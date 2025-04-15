// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.21;

/**
 * @title Simple Compound v3 Loan Contract
 * @notice This contract allows users to deposit collateral, borrow a base asset,
 * withdraw collateral, and repay their loan using Compound v3.  It's
 * simplified for educational purposes and omits some production-level
 * considerations.
 */
interface ICompound {
    function deposit(address asset, uint256 amount, address account) external;
    function withdraw(address asset, uint256 amount, address account) external;
    function borrow(address asset, uint256 amount, address account) external;
    function repay(address asset, uint256 amount, address account) external;
    function getAssetInfo(
        address asset
    )
        external
        view
        returns (
            uint8 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationPenalty,
            uint256 supplyCap,
            uint256 borrowCap
        );
    function accountLiquidity(
        address account
    ) external view returns (uint256 shortfall, uint256 liquidity);
}
