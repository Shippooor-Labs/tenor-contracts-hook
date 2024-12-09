// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { FixedTokenFactory } from "./tokens/FixedTokenFactory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

library MarketAdmin {
    using SafeERC20 for IERC20Metadata;

    function setFees(uint8 feeShare) external {
        MarketState storage m = PoolStorage.getMarketState();
        m.feeShare = feeShare;

        emit Events.SetFees(feeShare);
    }

    function listPool(uint40 maturity, uint40 maxTenorLength) external {
        // is under max tenor length
        require(maturity.timeToMaturity().lte(maxTenorLength));

        mapping(uint256 => address) storage fixedTokens = PoolStorage.getFixedToken();
        // Cannot already be deployed
        require(fixedTokens[maturity] == address(0));

        mapping(uint256 => address) storage fixedDebt = PoolStorage.getFixedDebtToken();
        // Cannot already be deployed
        require(fixedDebt[maturity] == address(0));

        (address f, address d) = FixedTokenFactory.createFixedToken(maturity);
        fixedTokens[maturity] = f;
        fixedDebt[maturity] = d;

        emit Events.ListPool(maturity, f, d);
    }

    function redeemRewards(
        address token,
        address underlyingToken,
        address loanToken,
        address receiver
    ) external returns (uint256 amount) {
        // Prevent redeeming underlying and loan tokens.
        require(token != underlyingToken && token != loanToken);

        // TODO: To handle the case where a collateral token is also given as a reward, we can store
        // the total collateral amount per currency and then transfer the balanceOf - totalCollateral

        // Prevents redeeming any collateral tokens.
        require(CurrencyId.unwrap(PoolStorage.getTokenToCurrencyLookupStorage()[token]) == 0);

        amount = IERC20Metadata(token).balanceOf(address(this));
        IERC20Metadata(token).safeTransfer(receiver, amount);

        emit Events.RedeemRewards(token, amount);
    }
}
