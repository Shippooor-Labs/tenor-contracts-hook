// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./Market.sol";
import { BaseHook } from "v4-periphery/base/hooks/BaseHook.sol";
import { Hooks } from "v4-core/libraries/Hooks.sol";
import { IHooks } from "v4-core/interfaces/IHooks.sol";
import { IPoolManager } from "v4-core/interfaces/IPoolManager.sol";
import { PoolKey } from "v4-core/types/PoolKey.sol";
import { BalanceDelta } from "v4-core/types/BalanceDelta.sol";
import { BeforeSwapDelta, toBeforeSwapDelta } from "v4-core/types/BeforeSwapDelta.sol";
import { PoolId, PoolIdLibrary } from "v4-core/types/PoolId.sol";
import { Currency } from "v4-core/types/Currency.sol";
import { CurrencySettler } from "@uniswap/v4-core/test/utils/CurrencySettler.sol";
import { MarketAdmin } from "./MarketAdmin.sol";

contract UniswapV4Market is Market, BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencySettler for Currency;

    error AddLiquidityThroughHook();
    error RemoveLiquidityThroughHook();

    mapping(PoolId => uint40) public poolIdToMaturity;
    IPoolManager public uniswapPoolManager;

    event UniswapV4PoolListed(uint256 maturity, PoolId poolId);

    constructor(
        IPoolManager _poolManager,
        IERC20Metadata loanToken,
        IERC20Metadata underlyingToken,
        uint8 maxTick,
        uint8 bpsPerTick,
        uint40 maxTenorLength,
        IMoneyMarketAdapter moneyMarketAdapter,
        bytes32 moneyMarketAdapterIdentifier
    )
        Market(
            loanToken,
            underlyingToken,
            maxTick,
            bpsPerTick,
            maxTenorLength,
            moneyMarketAdapter,
            moneyMarketAdapterIdentifier
        )
        BaseHook(_poolManager)
    {
        uniswapPoolManager = _poolManager;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true, // Don't allow adding liquidity normally
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true, // Don't allow removing liquidity normally
            afterRemoveLiquidity: false,
            beforeSwap: true, // Override how swaps are done
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: true, // Allow beforeSwap to return a custom delta
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // Disable adding liquidity through the Pool Manager
    // Liquidity is added through the Market contract's addLiquidity and lend / borrow functions (with isLimitOrder
    // parameter set to true).
    function beforeAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert AddLiquidityThroughHook();
    }

    // Disable removing liquidity through the Pool Manager
    // Liquidity is removed through the Market contract's withdrawLiquidity and withdrawLimitOrder functions.
    function beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert RemoveLiquidityThroughHook();
    }

    enum CallbackType {
        ADD_LIQUIDITY,
        WITHDRAW_LIQUIDITY,
        BORROW_WITHIN_MARKET,
        LEND_WITHIN_MARKET
    }

    struct CallbackData {
        CallbackType callbackType;
        uint40 maturity;
        uint256 fixedAmount;
        uint256 loanAmount;
    }

    /**
     * Extends the original _updateAccountingOnPoolDeposit function to handle Uniswap v4 ERC-6909 claims.
     */
    function _updateAccountingOnPoolDeposit(
        uint40 maturity,
        uint8 tick,
        uint32 batchId,
        uint256 fixedIn,
        uint256 loanIn,
        uint256 sharesOut
    ) internal override returns (uint256 shares) {
        // At this point, the user has already deposited loan and fixed tokens into the market.
        super._updateAccountingOnPoolDeposit(maturity, tick, batchId, fixedIn, loanIn, sharesOut);

        // In order to enable swapping (lend / withdraw) through Uniswap V4, tokens need to be deposited into the pool
        // manager instead of the market.
        // The market will hold claims (ERC-6909) on tokens from the pool manager.
        // In order to deposit tokens into the pool manager and receive claims, we need to unlock the pool manager
        // first.

        CallbackData memory callbackData = CallbackData({
            callbackType: CallbackType.ADD_LIQUIDITY,
            maturity: maturity,
            fixedAmount: fixedIn,
            loanAmount: loanIn
        });

        // This will call _unlockCallback using callbackData as parameters.
        uniswapPoolManager.unlock(abi.encode(callbackData));
    }

    /**
     * Extends the original _updateAccountingOnPoolWithdraw function to handle Uniswap v4 ERC-6909 claims.
     */
    function _updateAccountingOnPoolWithdraw(
        uint40 maturity,
        uint8 tick,
        uint32 batchId,
        uint256 fixedOut,
        uint256 loanOut,
        uint256 sharesIn
    ) internal override {
        super._updateAccountingOnPoolWithdraw(maturity, tick, batchId, fixedOut, loanOut, sharesIn);

        // Market holds claims (ERC-6909) on fixed and loan tokens from the pool manager.
        // In order for the user to be able to withdraw their tokens from the market,
        // claims need to be burned, then fixed and loan tokens need to be transferred back to the market.
        // In order to do so, we need to unlock the pool manager.
        CallbackData memory callbackData = CallbackData({
            callbackType: CallbackType.WITHDRAW_LIQUIDITY,
            maturity: maturity,
            fixedAmount: fixedOut,
            loanAmount: loanOut
        });

        // This will call _unlockCallback using callbackData as parameters.
        uniswapPoolManager.unlock(abi.encode(callbackData));
    }

    /**
     * Extends the original _updateAccountingOnTrade function to handle Uniswap v4 ERC-6909 claims.
     * Gets called when swap is executed using borrow / lend functions in the Market contract.
     */
    function _updateAccountingOnTrade(
        uint40 maturity,
        uint256 amountIn,
        uint256 amountOut,
        bool isLoanOut
    ) internal override {
        super._updateAccountingOnTrade(maturity, amountIn, amountOut, isLoanOut);

        // Filled limit orders and market fees are intendedly left onto the pool to be claimed later, although they
        // are not tradable anymore. This is done to avoid extra transfers and to keep the accounting simple.

        CallbackData memory callbackData;
        if (isLoanOut) {
            callbackData = CallbackData({
                callbackType: CallbackType.BORROW_WITHIN_MARKET,
                maturity: maturity,
                fixedAmount: liquidityOut,
                loanAmount: liquidityIn
            });
        } else {
            callbackData = CallbackData({
                callbackType: CallbackType.LEND_WITHIN_MARKET,
                maturity: maturity,
                fixedAmount: liquidityIn,
                loanAmount: liquidityOut
            });
        }

        // This will call _unlockCallback using callbackData as parameters.
        uniswapPoolManager.unlock(abi.encode(callbackData));
    }

    function _unlockCallback(bytes calldata data) internal override returns (bytes memory) {
        CallbackData memory callbackData = abi.decode(data, (CallbackData));

        Currency fixedCurrency = Currency.wrap(PoolStorage.getFixedToken()[callbackData.maturity]);
        Currency loanCurrency = Currency.wrap(address(LOAN_TOKEN));

        if (callbackData.callbackType == CallbackType.ADD_LIQUIDITY) {
            // Transfer fixed tokens from the hook (market) to the pool manager
            fixedCurrency.settle(
                uniswapPoolManager,
                address(this), // The hook (market) holds the fixed tokens for the user
                callbackData.fixedAmount,
                false // If false, ERC20-transfer to the PoolManager
            );

            // Transfer loan tokens from the hook (market) to the pool manager
            loanCurrency.settle(
                uniswapPoolManager,
                address(this), // The hook (market) holds the loan tokens for the user
                callbackData.loanAmount,
                false // If false, ERC20-transfer to the PoolManager
            );

            // Mint and transfer fixed tokens claims from the pool manager to the hook
            fixedCurrency.take(
                uniswapPoolManager,
                address(this), // The hook (market) is the recipient
                callbackData.fixedAmount,
                true // If true, mint the ERC-6909 token
            );

            // Mint and transfer loan tokens claims from the pool manager to the hook
            loanCurrency.take(
                uniswapPoolManager,
                address(this), // The hook (market) is the recipient
                callbackData.loanAmount,
                true // If true, mint the ERC-6909 token
            );
        } else if (callbackData.callbackType == CallbackType.WITHDRAW_LIQUIDITY) {
            // Transfer fixed token claims from the hook to the pool manager and burn them.
            fixedCurrency.settle(
                uniswapPoolManager,
                address(this), // The hook (market) holds the ERC-6909 token for the user
                callbackData.fixedAmount,
                true // If true, burn the ERC-6909 token
            );

            // Transfer loan token claims from the hook to the pool manager and burn them.
            loanCurrency.settle(
                uniswapPoolManager,
                address(this), // The hook (market) holds the ERC-6909 token for the user
                callbackData.loanAmount,
                true // If true, burn the ERC-6909 token
            );

            // Transfer fixed tokens from the pool manager to the hook
            fixedCurrency.take(
                uniswapPoolManager,
                address(this), // The hook (market) receives the fixed tokens
                callbackData.fixedAmount,
                false // If false, ERC20-transfer from the PoolManager to recipient
            );

            // Transfer loan tokens from the pool manager to the hook
            loanCurrency.take(
                uniswapPoolManager,
                address(this), // The hook (market) receives the loan tokens
                callbackData.loanAmount,
                false // If false, ERC20-transfer from the PoolManager to recipient
            );
        } else if (callbackData.callbackType == CallbackType.LEND_WITHIN_MARKET) {
            // Send incoming pool liquidity ERC-20 tokens from the hook to the pool manager
            loanCurrency.settle(
                uniswapPoolManager,
                address(this), // The hook (market) is the payer.
                callbackData.loanAmount,
                false // If false, ERC20-transfer from the hook to the pool manager
            );

            // Mint ERC-6909 claims for incoming pool liquidity and send to the hook
            loanCurrency.take(
                uniswapPoolManager,
                address(this), // The hook (market) is the recipient
                callbackData.loanAmount,
                true // If true, mint the ERC-6909 token and transfer to the hook
            );

            // Burn ERC-6909 claims for outgoing pool liquidity.
            fixedCurrency.settle(
                uniswapPoolManager,
                address(this), // The hook (market) holds the ERC-6909 token
                callbackData.fixedAmount,
                true // If true, transfer the ERC-6909 tokens to the pool manager and burn them
            );

            // Send outgoing pool liquidity ERC-20 tokens from the pool manager to the hook.
            fixedCurrency.settle(
                uniswapPoolManager,
                address(this), // The hook (market) receives the ERC-20 tokens.
                callbackData.fixedAmount,
                false // If false, ERC20-transfer from the PoolManager to the hook
            );
        } else if (callbackData.callbackType == CallbackType.BORROW_WITHIN_MARKET) {
            // Send incoming pool liquidity ERC-20 tokens from the hook to the pool manager
            fixedCurrency.settle(
                uniswapPoolManager,
                address(this), // The hook (market) is the payer.
                callbackData.fixedAmount,
                false // If false, ERC20-transfer from the hook to the pool manager
            );

            // Mint ERC-6909 claims for incoming pool liquidity and send to the hook
            fixedCurrency.take(
                uniswapPoolManager,
                address(this), // The hook (market) is the recipient
                callbackData.fixedAmount,
                true // If true, mint the ERC-6909 token and transfer to the hook
            );

            // Burn ERC-6909 claims for outgoing pool liquidity.
            loanCurrency.settle(
                uniswapPoolManager,
                address(this), // The hook (market) holds the ERC-6909 token
                callbackData.loanAmount,
                true // If true, transfer the ERC-6909 tokens to the pool manager and burn them
            );

            // Send outgoing pool liquidity ERC-20 tokens from the pool manager to the hook.
            loanCurrency.settle(
                uniswapPoolManager,
                address(this), // The hook (market) receives the ERC-20 tokens.
                callbackData.loanAmount,
                false // If false, ERC20-transfer from the PoolManager to the hook
            );
        }

        return "";
    }

    function beforeSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) external override returns (bytes4 selector, BeforeSwapDelta delta, uint24) {
        uint40 maturity = poolIdToMaturity[key.toId()];
        if (maturity == 0) revert("Pool not listed");

        // There are 8 possible cases that need to be handled:

        // Lend cases (fixed token is the output currency)
        // 1. Currency0 = Loan Token, Currency1 = Fixed Token, Exact Input, zeroForOne = true
        // 2. Currency0 = Loan Token, Currency1 = Fixed Token, Exact Output, zeroForOne = true
        // 3. Currency0 = Fixed Token, Currency1 = Loan Token, Exact Input, zeroForOne = false
        // 4. Currency0 = Fixed Token, Currency1 = Loan Token, Exact Output, zeroForOne = false

        // Borrow cases (loan token is the output currency)
        // 5. Currency0 = Fixed Token, Currency1 = Loan Token, Exact Input, zeroForOne = true
        // 6. Currency0 = Fixed Token, Currency1 = Loan Token, Exact Output, zeroForOne = true
        // 7. Currency0 = Loan Token, Currency1 = Fixed Token, Exact Input, zeroForOne = false
        // 8. Currency0 = Loan Token, Currency1 = Fixed Token, Exact Output, zeroForOne = false

        // Cases can be simplified by first determining if the swap is for lending or borrowing
        bool isLoanOut = Currency.unwrap(key.currency1) == address(LOAN_TOKEN) ? params.zeroForOne : !params.zeroForOne;

        // Then, since executeTrade handles the sign of the amount the same way Uniswap does (positive for exact input,
        // negative for exact output),
        // we can call executeTrade with the amountSpecified as is.
        (uint256 amountIn, uint256 amountOut) = PoolTrade.executeTrade(
            maturity,
            this.getLoanToAssetExchangeRate(),
            params.amountSpecified,
            isLoanOut ? MAX_TICK : 0, // No max slippage for lending (0) and borrowing (MAX_TICK)
            isLoanOut // If true, borrow. Otherwise lend
        );
        super._updateAccountingOnTrade(account, maturity, amountIn, amountOut, isLoanOut);

        (Currency currencyIn, Currency currencyOut) =
            params.zeroForOne ? (params.currency0, params.currency1) : (params.currency1, params.currency0);

        // Mint ERC-6909 claims for received currencyIn which stays in the pool.
        // Market fees and filled limit orders are intendedly left on the Pool Manager to avoid unnecessary transfers
        // and make swaps more efficient.
        currencyOut.take(
            uniswapPoolManager,
            address(this), // The hook (market) receives the ERC-6909 token
            amountIn,
            true // If true, mint the ERC-6909 token
        );

        // Burn ERC-6909 claims for amount of currencyOut which leaves the pool.
        // Market fees are intendedly left on the Pool Manager to avoid unnecessary transfers and make swaps more
        // efficient.
        currencyIn.settle(
            uniswapPoolManager,
            address(this), // The hook (market) holds the ERC-6909 token
            amountOut,
            true // If true, burn the ERC-6909 token
        );

        // User has a debit of amountIn and a credit of amountOut to be settled after the swap.
        delta = toBeforeSwapDelta(-int128(int256(amountIn)), int128(int256(amountOut)));

        return (this.beforeSwap.selector, delta, 0);
    }

    function listPool(uint40 maturity) external override {
        // Call the original listPool function to initialize the AMM and create fixed tokens.
        MarketAdmin.listPool(maturity, MAX_TENOR_LENGTH);

        // Initialize the Uniswap v4 poola
        address fixedToken = this.fixedToken(maturity);
        require(fixedToken != address(0), "Fixed token not found for maturity");

        // Create a new Uniswap v4 pool for this maturity
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(LOAN_TOKEN)),
            currency1: Currency.wrap(fixedToken),
            fee: 0, // Fees are always set to 0 since the market handles fees internally
            tickSpacing: 1, // Tick spacing can be ignored since we are not using Uniswap V4's AMM
            hooks: IHooks(address(this))
        });

        // Ensure currencies are in the correct order
        if (uint160(address(LOAN_TOKEN)) > uint160(fixedToken)) {
            (poolKey.currency0, poolKey.currency1) = (poolKey.currency1, poolKey.currency0);
        }

        // Initialize the pool
        uniswapPoolManager.initialize(
            poolKey,
            1 // sqrtPriceX96 can be ignored since we are not using Uniswap V4's AMM
        );

        // Store the pool ID for this maturity
        poolIdToMaturity[poolKey.toId()] = maturity;

        emit UniswapV4PoolListed(maturity, poolKey.toId());
    }
}
