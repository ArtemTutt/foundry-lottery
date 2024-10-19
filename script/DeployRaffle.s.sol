// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() public {}

    function deployContract() public returns(Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();


        // if we use local network, we calling getOrCreateAnvilEthConfig()
        // or if we use sepolia or something like that, we callig getSepoliaEthConfig()
        // local => deploy mocks, get local config
        // sepolia => get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle();
        vm.stopBroadcast();
    }
}
