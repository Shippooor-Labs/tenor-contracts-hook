# Tenor Uniswap v4 Hook

This is a Uniswap v4 hook that allows users to lend at fixed rate from a Tenor market.

## Note

Since the Tenor core contracts are not open source yet, this repository solely focuses on the Uniswap v4 hook.

A working demo using the core contracts is available [here](https://main.dvuogw9m3wruu.amplifyapp.com/).

## Design

The Uniswap v4 hook is deployed as a No-Op hook that overrides the following permissions on the Uniswap v4 pool manager:
- `beforeAddLiquidity`
- `beforeRemoveLiquidity`
- `beforeSwap`
- `beforeSwapReturnDelta`

The hook enables swapping between fixed tokens of any maturity (zero coupon bonds) and the loan token as configured in the market. The swap is executed using the Tenor fixed rate AMM instead of Uniswap's AMM.

For more details on how the Tenor fixed rate AMM works, see [here](https://docs.tenor.finance/).

On a high level, the hook directly extends the Tenor market contract and overrides internal functions to handle Uniswap v4 ERC-6909 claims. In other words, the hook is binded 1:1 with individual instances of the market contract, and is not intended to be used in a generic way.

### Listing a new maturity
Market admin is responsible for listing new maturities on a market. The `listPool` function in the `UniswapV4Market` contract is used to initialize the AMM and create fixed tokens for a new maturity. The function will also list the pool on Uniswap v4.

### Adding and removing liquidity
The `addLiquidity` and `removeLiquidity` behaviors are disabled in the hook. Liquidity is added through the Market contract's `addLiquidity` and `lend`/`borrow` functions (with `isLimitOrder` parameter set to `true`).

ERC-6909 claims for liquidity are handled through the `_updateAccountingOnPoolWithdraw` and `_updateAccountingOnPoolDeposit` functions.

### Swapping
The `swap` behavior is overridden in the hook to handle swapping between fixed tokens and the loan token through the Tenor fixed rate AMM.

Users are also still able to use the `lend` and `borrow` functions from the Market contract to swap between fixed tokens and the loan token. In this case, the Uniswap v4 hook ensures the ERC-6909 claims are correctly handled (see `_updateAccountingOnTrade` function for details).
