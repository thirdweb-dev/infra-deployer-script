// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InfraDeployer} from "contract-deployment-infra/InfraDeployer.sol";

import {MintFeeManagerCore} from "modular-contracts/core/MintFeeManagerCore.sol";
import {MintFeeManagerModule} from "modular-contracts/module/MintFeeManagerModule.sol";

import {SplitFeesCore} from "modular-contracts/core/SplitFeesCore.sol";
import {SplitFeesModule} from "modular-contracts/module/SplitFeesModule.sol";

contract InfraDeployerScript is Script {
    address factory = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    function setUp() public {}

    function _getAddress(bytes memory creationCode, bytes memory encodedArgs, bytes32 salt)
        internal
        view
        virtual
        returns (address)
    {
        bytes32 bytecodeHash = keccak256(abi.encodePacked(creationCode, encodedArgs));

        bytes32 rawAddress = keccak256(abi.encodePacked(bytes1(0xff), factory, salt, bytecodeHash));
        return address(uint160(uint256(rawAddress)));
    }

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        uint256 privateKey1 = vm.envUint("PRIVATE_KEY_1");
        uint256 privateKey2 = vm.envUint("PRIVATE_KEY_2");
        address signer1 = vm.addr(privateKey1);
        address signer2 = vm.addr(privateKey2);
        vm.startBroadcast(privateKey);

        // set up multisig signers
        address[] memory signers = new address[](2);
        signers[0] = signer1;
        signers[1] = signer2;

        // deploy contract deployment infra
        bytes memory encodedArgs = abi.encode(signers, 1);
        bytes memory deployCalldata =
            abi.encodePacked(keccak256("thirdweb"), type(InfraDeployer).creationCode, encodedArgs);
        factory.call(deployCalldata);

        address infraDeployerAddress = _getAddress(type(InfraDeployer).creationCode, encodedArgs, keccak256("thirdweb"));
        InfraDeployer deploymentInfra = InfraDeployer(infraDeployerAddress);
        address owner = deploymentInfra.owner();
        console.log("InfraDeployer deployed: ", address(deploymentInfra));
        console.log("mutlisig owner: ", owner);

        // set up creation code
        bytes[] memory creationCode = new bytes[](2);
        creationCode[0] = abi.encodePacked(type(MintFeeManagerCore).creationCode);
        creationCode[1] = abi.encodePacked(type(SplitFeesCore).creationCode);

        // set up constructor args
        bytes[] memory constructorArgs = new bytes[](2);

        address mintFeeManagerModule = address(new MintFeeManagerModule());
        address splitFeesModule = address(new SplitFeesModule());

        address[] memory mintFeeManagerModules = new address[](1);
        bytes[] memory mintFeeManagerModuleData = new bytes[](1);
        bytes memory mintFeeManagerData = MintFeeManagerModule(mintFeeManagerModule).encodeBytesOnInstall(owner, 300);
        mintFeeManagerModules[0] = mintFeeManagerModule;
        mintFeeManagerModuleData[0] = mintFeeManagerData;

        address[] memory splitFeesModules = new address[](1);
        bytes[] memory splitFeesModuleData = new bytes[](1);
        splitFeesModules[0] = splitFeesModule;

        constructorArgs[0] = abi.encode(owner, mintFeeManagerModules, mintFeeManagerModuleData);
        constructorArgs[1] = abi.encode(owner, splitFeesModules, splitFeesModuleData);

        // prepare salt
        bytes32[] memory salts = new bytes32[](2);
        salts[0] = keccak256(abi.encodePacked("thirdweb"));
        salts[1] = keccak256(abi.encodePacked("thirdweb"));

        // deploy contracts
        address[] memory deployedContracts =
            deploymentInfra.deployDeterministicBatch(creationCode, constructorArgs, salts);
        console.log("contracts deployed");
        console.log("MintFeeManagerCore deployed: ", deployedContracts[0]);
        console.log("SplitFeesCore deployed: ", deployedContracts[1]);

        vm.stopBroadcast();
    }
}
