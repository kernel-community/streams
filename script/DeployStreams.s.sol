// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.8.19;

import { Script } from "forge-std/Script.sol";
import { Streams } from "../src/Streams.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployStreams is Script {
    address internal deployer;
    Streams internal streams;

    function setUp() public virtual {
        string memory mnemonic = vm.envString("MNEMONIC");
        (deployer,) = deriveRememberKey(mnemonic, 0);
    }

    function run() public {
        vm.startBroadcast(deployer);
        streams = new Streams();
        vm.stopBroadcast();
    }
}
