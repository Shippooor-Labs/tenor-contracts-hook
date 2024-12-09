// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Market is ReentrancyGuard {
    IERC20Metadata public immutable LOAN_TOKEN;
    IERC20Metadata public immutable UNDERLYING_TOKEN;
    address public immutable ADMIN;

    uint8 public immutable BPS_PER_TICK;
    uint8 public immutable MAX_TICK;
    uint40 public immutable MAX_TENOR_LENGTH;

    constructor(
        IERC20Metadata loanToken,
        IERC20Metadata underlyingToken,
        uint8 maxTick,
        uint8 bpsPerTick,
        uint40 maxTenorLength
    ) {
        require(maxTick < 111);

        LOAN_TOKEN = loanToken;
        UNDERLYING_TOKEN = underlyingToken;
        MAX_TENOR_LENGTH = maxTenorLength;
        MAX_TICK = maxTick;
        BPS_PER_TICK = bpsPerTick;
        ADMIN = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == ADMIN);
        _;
    }

    modifier checkHealth(address to) {
        // Code removed.
        _;
    }

    modifier checkInvariant(uint40 maturity) {
        // Code removed.
        _;
    }

    function setFees(uint8 feeShare) external onlyAdmin {
       // Code removed.
    }

    function listPool(uint40 maturity) external virtual onlyAdmin {
       // Code removed.
    }

    function claimRewards(address token) external onlyAdmin {
       // Code removed.
    }

    function redeemRewards(address token) external onlyAdmin returns (uint256 amount) {
       // Code removed.
    }

    /**
     * VIEW METHODS
     */
    function fixedToken(uint40 maturity) public view returns (IERC4626) {
        // Code removed.
    }

    function fixedDebtToken(uint40 maturity) public view returns (IERC4626) {
        // Code removed.
    }

    function getLoanToAssetExchangeRate() public view returns (uint256) {
        // Code removed.
    }

    function getTotalFixedLiquidity(uint40 maturity) external view returns (uint256) {
        // Code removed.
    }

    function getTotalLoanLiquidity(uint40 maturity) external view returns (uint256) {
        // Code removed.
    }

    function getFixedTokenTotalSupply(uint40 maturity) external view returns (uint256) {
        // Code removed.
    }

    function getFixedRateTokenBalance(address account, uint40 maturity) external view returns (int256) {
        // Code removed.
    }

    function getLoanTokenBalance(address account) external view returns (uint256) {
        // Code removed.
    }

    /**
     * LIQUIDITY METHODS
     */

    /// @notice Withdraw a limit order from the pool
    /// @param maturity timestamp of the maturity
    /// @param tick tick index
    /// @param batchId batch id of the limit order
    /// @param shares amount of liquidity to withdraw
    /// @return fixedOut amount of fixed tokens withdrawn
    /// @return loanOut amount of loan tokens withdrawn
    /// @dev this function is agnostic of the limit order state (unfilled, partially filled, filled)
    function withdrawLimitOrder(
        uint40 maturity,
        uint8 tick,
        uint32 batchId,
        uint256 shares
    )
        external
        checkInvariant(maturity)
        checkHealth(msg.sender)
        nonReentrant
        returns (uint256 fixedOut, uint256 loanOut)
    {
       // Code removed.
    }

    /// @notice Add liquidity to the pool
    /// @param maturity timestamp of the maturity
    /// @param tick tick index
    /// @param fixedAmount amount of fixed tokens to add
    /// @param loanAmount amount of loan tokens to add
    /// @return shares amount of liquidity tokens minted
    function addLiquidity(
        uint40 maturity,
        uint8 tick,
        uint256 fixedAmount,
        uint256 loanAmount
    ) external checkInvariant(maturity) checkHealth(msg.sender) nonReentrant returns (uint256 shares) {
       // Code removed.
    }

    /// @notice Withdraw liquidity to the pool
    /// @param maturity timestamp of the maturity
    /// @param tick tick index
    /// @param shares amount of liquidity tokens
    /// @return fixedAmount amount of fixed tokens withdrawn
    /// @return loanAmount amount of loan tokens withdrawn
    function withdrawLiquidity(
        uint40 maturity,
        uint8 tick,
        uint256 shares
    )
        external
        checkInvariant(maturity)
        checkHealth(msg.sender)
        nonReentrant
        returns (uint256 fixedAmount, uint256 loanAmount)
    {
       // Code removed.
    }

    /**
     * TRADING METHODS
     */

    /// @notice Simulate a trade in the pool.
    /// @param maturity timestamp of the maturity
    /// @param amount if positive: amount of token going in, if negative: amount going out.
    /// @param limitTick limit interest rate tick index, equivalent to the maximum slippage
    /// @param isLoanOut whether the trade is a loan out or fixed out
    /// @return amountInFilled amount of tokens traded in
    /// @return amountOutFilled amount of tokens trade out
    function simulateTrade(
        uint40 maturity,
        int256 amount,
        uint8 limitTick,
        bool isLoanOut
    ) external view returns (uint256 amountInFilled, uint256 amountOutFilled) {
       // Code removed.
    }

    /// @notice Lend in a pool.
    /// @param maturity timestamp of the maturity
    /// @param amount if positive: amountIn denoted in loan, if negative: amountOut denoted in fixed
    /// @param limitTick limit interest rate tick index, equivalent to the maximum slippage
    /// @param isLimitOrder whether to place a limit order if not enough liquidity
    /// @return amountInFilled amount of loan tokens traded for fixed tokens
    /// @return amountOutFilled amount of fixed tokens traded for loan tokens
    /// @return batchId limit order batch id or zero if not applicable
    /// @dev reverts if this is not a limit order and the trade is not fully filled or when trying to set a limit order
    /// in fixed amount
    function lend(
        uint40 maturity,
        int256 amount,
        uint8 limitTick,
        bool isLimitOrder
    )
        external
        checkInvariant(maturity)
        checkHealth(msg.sender)
        nonReentrant
        returns (uint256 amountInFilled, uint256 amountOutFilled, uint32 batchId)
    {
       // Code removed.
    }

    /// @notice Borrow in a pool.
    /// @param maturity timestamp of the maturity
    /// @param amount if positive: amountIn denoted in fixed, if negative: amountOut denoted in loan
    /// @param limitTick limit interest rate tick index, equivalent to the maximum slippage
    /// @param isLimitOrder whether to place a limit order if not enough liquidity
    /// @return amountInFilled amount of fixed tokens traded for loan tokens
    /// @return amountOutFilled amount of loan tokens traded for fixed tokens
    /// @return batchId limit order batch id or zero if not applicable
    /// @dev reverts if this is not a limit order and the trade is not fully filled or when trying to set a limit order
    /// in loan amount
    function borrow(
        uint40 maturity,
        int256 amount,
        uint8 limitTick,
        bool isLimitOrder
    )
        external
        checkInvariant(maturity)
        checkHealth(msg.sender)
        nonReentrant
        returns (uint256 amountInFilled, uint256 amountOutFilled, uint32 batchId)
    {
        // Code removed.
    }

    /**
     * TRANSFER METHODS
     */

    /// @notice Deposit collateral tokens into the market.
    /// @param token Address of the collateral token.
    /// @param amount Amount of collateral tokens to deposit.
    /// @dev msg.sender must have approved the market contract to spend the collateral tokens.
    function depositCollateral(address token, uint256 amount) external nonReentrant {
        // Code removed.
    }

    /// @notice Withdraw collateral tokens into the market.
    /// @param token Address of the collateral token.
    /// @param amount Amount of collateral tokens to withdraw.
    function withdrawCollateral(address token, uint256 amount) external checkHealth(msg.sender) nonReentrant {
        // Code removed.
    }

    /// @notice Deposit underlying tokens into the market.
    /// @param amount Amount of underlying tokens to deposit.
    /// @return loanAmount Amount of loan tokens deposited.
    /// @dev msg.sender must have approved the market contract to spend the underlying tokens.
    function deposit(uint256 amount) external nonReentrant returns (uint256 loanAmount) {
        // Code removed.
    }

    /// @notice Deposit loan tokens into the market.
    /// @param amount Amount of loan tokens to deposit.
    /// @return loanAmount Amount of loan tokens deposited.
    /// @dev msg.sender must have approved the market contract to spend the loan tokens.
    function depositLoan(uint256 amount) external nonReentrant returns (uint256 loanAmount) {
        // Code removed.
    }

    /// @notice withdraw underlying tokens from the market.
    /// @param amount Amount of underlying tokens to withdraw.
    function withdraw(uint256 amount) external nonReentrant checkHealth(msg.sender) {
        // Code removed.
    }

    /// @notice withdraw loan tokens from the market.
    /// @param amount Amount of loan tokens to withdraw.
    function withdrawLoan(uint256 amount) external nonReentrant checkHealth(msg.sender) {
        // Code removed.
    }

    function transferFixed(
        address to,
        uint256 amount,
        uint40 maturity
    ) external nonReentrant checkHealth(msg.sender) returns (bool success) {
        // Code removed.
    }

    function transferFromFixed(
        address from,
        address to,
        uint256 amount,
        uint40 maturity
    ) external nonReentrant checkHealth(from) returns (bool success) {
        // Code removed.

    }

    function allowanceFixed(address owner, address spender, uint40 maturity) external view returns (uint256) {
        // Code removed.
    }

    function approveFixed(
        address spender,
        uint256 value,
        uint40 maturity
    ) external nonReentrant checkHealth(msg.sender) returns (bool success) {
        // Code removed.
    }
}
