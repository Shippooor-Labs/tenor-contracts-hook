// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.25;

import "./FixedBase.sol";
import { BalanceLib } from "@types/Balance.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title FixedDebt
/// @author Tenor Labs
/// @custom:contact security@tenor.finance
/// @notice ERC20 compliant fixed debt token contract that is minted simultaneously as a pair with fixed rate tokens.
contract FixedDebt is FixedBase {
    using Strings for uint256;
    using uint40Lib for uint40;
    using InterestRateLib for InterestRate;
    using ExchangeRateLib for ExchangeRate;

    /// @dev A Fixed debt token contract is always created when listing new pools.
    /// @param maturity_ Maturity of the Tenor pool this token belongs to.
    constructor(uint40 maturity_) FixedBase(maturity_) { }

    function name() public view returns (string memory) {
        return string(
            abi.encodePacked("Fixed Debt", MARKET.LOAN_TOKEN().name(), " ", uint40.unwrap(super.maturity()).toString())
        );
    }

    function symbol() public view returns (string memory) {
        return string(
            abi.encodePacked("fixedDebt", MARKET.LOAN_TOKEN().symbol(), uint40.unwrap(super.maturity()).toString())
        );
    }

    function balanceOf(address account) public view override returns (uint256) {
        int256 netBalance = MARKET.getFixedRateTokenBalance(account, _maturity);
        return netBalance < 0 ? uint256(-1 * netBalance) : 0;
    }

    function getCurrentExchangeRate() public view override returns (uint256) {
        // Code removed.
    }

    function totalSupply() public view override returns (uint256) {
        // Code removed.
    }

    /// @inheritdoc FixedBase
    function isDebt() external pure override returns (bool) {
        return true;
    }

    /// @inheritdoc FixedBase
    function getCurrentInterestRate() public view override returns (uint256) {
        // Code removed.
    }

    /// @inheritdoc FixedBase
    function latestAnswer() public view override returns (int256) {
        // Code removed.
    }
}
