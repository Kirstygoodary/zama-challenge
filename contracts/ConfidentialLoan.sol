// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {euint64, ebool, eaddress, TFHE, euint256} from "fhevm/lib/TFHE.sol";
import {Gateway} from "fhevm/gateway/lib/Gateway.sol";
import {ZamaFHEVMConfig} from "fhevm/config/ZamaFHEVMConfig.sol";
import {ZamaGatewayConfig} from "fhevm/config/ZamaGatewayConfig.sol";
import "./ICompound.sol";

contract ConfidentialLoan is ReentrancyGuard {
    using SafeCast for uint256;

    struct Loan {
        euint64 encryptedAmount;
        bool active;
    }

    // collateral address
    eaddress collateralToken;
    // mappiing of address to collateral
    mapping(eaddress => euint256) collateral;
    // mapping of address to loans
    mapping(eaddress => Loan) public loans;
    // Cpmound address
    ICompound public compound;

    //  Loan status is tracked implicitly through deposits and borrows in Compound
    //  This contract focuses on managing interaction with Compound V3

    event Deposited(
        eaddress indexed user,
        eaddress indexed asset,
        euint256 amount
    );
    event Withdrawn(
        eaddress indexed user,
        eaddress indexed asset,
        euint256 amount
    );
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);

    /**
     * @param _compound The address of the Compound v3 hub.
     */
    constructor(address _compound, eaddress _collateral) {
        TFHE.setFHEVM(ZamaFHEVMConfig.getSepoliaConfig());
        Gateway.setGateway(ZamaGatewayConfig.getSepoliaConfig());
        compound = ICompound(_compound);
    }

    function requestAddress() public {
        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(collateralToken);
        Gateway.requestDecryption(
            cts,
            this.callbackAddress.selector,
            0,
            block.timestamp + 100,
            false
        );
    }

    function callbackAddress(
        uint256,
        address decryptedInput
    ) public onlyGateway returns (address) {
        return decryptedInput;
    }

    /**
     * @notice Deposits collateral to Compound.  The user must first approve this
     * contract to spend the collateral asset.
     * @param _asset The address of the collateral asset.
     * @param _amount The amount of the collateral asset to deposit.
     */
    function deposit(
        euint256 _amount,
        bytes calldata _inputProofToken,
        bytes calldata _inputProofAmount
    ) external nonReentrant {
        // Transfer collateral from the user to this contract
        IERC20(TFHE.asEaddress(collateralToken, _inputProofToken)).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // Deposit collateral into Compound from this contract and the depositor.
        compound.deposit(
            eaddress.unwrap(collateralToken),
            euint256.unwrap(_amount),
            address(this)
        );
        emit Deposited(eaddress.wrap(msg.sender), collateralToken, _amount);
    }

    // /**
    //  * @notice Withdraws collateral from Compound.
    //  * @param _asset The address of the collateral asset.
    //  * @param _amount The amount of the collateral asset to withdraw.
    //  */
    // function withdraw(address _asset, uint256 _amount) external nonReentrant {
    //     // Withdraw collateral from Compound
    //     compound.withdraw(_asset, _amount, msg.sender); // Use msg.sender as the account

    //     // Transfer collateral from this contract to the user
    //     IERC20 collateralToken = collateralAssets[_asset];
    //     collateralToken.transfer(msg.sender, _amount);
    //     emit Withdrawn(msg.sender, _asset, _amount);
    // }

    // /**
    //  * @notice Borrows the base asset from Compound.  The user must have
    //  * sufficient collateral in Compound.
    //  * @param _amount The amount of the base asset to borrow.
    //  */
    // function borrow(uint256 _amount) external nonReentrant {
    //     // Borrow from Compound
    //     compound.borrow(address(baseAsset), _amount, msg.sender); // Use msg.sender
    //     emit Borrowed(msg.sender, _amount);
    // }

    // /**
    //  * @notice Repays the borrowed base asset to Compound. The user must first
    //  * approve this contract to spend the base asset.
    //  * @param _amount The amount of the base asset to repay.
    //  */
    // function repay(uint256 _amount) external nonReentrant {
    //     // Transfer base asset from the user to this contract
    //     baseAsset.transferFrom(msg.sender, address(this), _amount);

    //     // Repay the loan to Compound
    //     compound.repay(address(baseAsset), _amount, msg.sender); // Use msg.sender
    //     emit Repaid(msg.sender, _amount);
    // }

    // /**
    //  * @notice Gets the user's account liquidity and shortfall in Compound.
    //  * @return shortfall The shortfall amount.
    //  * @return liquidity The liquidity amount.
    //  */
    // function getAccountLiquidity()
    //     external
    //     view
    //     returns (uint256 shortfall, uint256 liquidity)
    // {
    //     (shortfall, liquidity) = compound.accountLiquidity(msg.sender);
    // }

    // /**
    //  * @notice Gets the asset information from Compound.
    //  * @param _asset The address of the asset.
    //  * @return decimals The decimals of the asset.
    //  * @return ltv The loan-to-value ratio.
    //  * @return liquidationThreshold The liquidation threshold.
    //  * @return liquidationPenalty The liquidation penalty.
    //  * @return supplyCap The supply cap.
    //  * @return borrowCap The borrow cap.
    //  */
    // function getAssetInfo(
    //     address _asset
    // )
    //     external
    //     view
    //     returns (
    //         uint8 decimals,
    //         uint256 ltv,
    //         uint256 liquidationThreshold,
    //         uint256 liquidationPenalty,
    //         uint256 supplyCap,
    //         uint256 borrowCap
    //     )
    // {
    //     return compound.getAssetInfo(_asset);
    // }

    // Fallback function to receive Ether (if any is sent)
    receive() external payable {}
}
