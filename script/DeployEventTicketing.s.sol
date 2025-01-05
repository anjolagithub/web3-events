// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { EventFactory } from "../src/EventFactory.sol";
import { EventTicketing } from "../src/EventTicketing.sol";

contract DeployEventTicketing is Script {

    function run() public {
        // Get deployer's private key from environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);  // Use the provided private key to get deployer address

        // Deploy EventFactory contract
        vm.startBroadcast(deployer);
        EventFactory eventFactory = new EventFactory();
        vm.stopBroadcast();

        // Deploy EventTicketing contract, passing the EventFactory address to the constructor
        vm.startBroadcast(deployer);
        EventTicketing eventTicketing = new EventTicketing(address(eventFactory));
        vm.stopBroadcast();

        // Optionally, set the base URI for tickets (if necessary)
        string memory baseURI = "https://myapi.com/tickets/";  // Example URI
        vm.startBroadcast(deployer);
        eventTicketing.updateTicketBaseURI(baseURI);
        vm.stopBroadcast();

        // Log the deployed contract addresses
        console.log("EventFactory deployed at:", address(eventFactory));
        console.log("EventTicketing deployed at:", address(eventTicketing));
    }
}
