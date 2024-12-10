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
