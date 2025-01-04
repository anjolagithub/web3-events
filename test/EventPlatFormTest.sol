// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {EventFactory} from "../src/EventFactory.sol";
import {EventTicketing} from "../src/EventTicketing.sol";
import {EventEscrow} from "../src/EventEscrow.sol";

contract EventPlatformTest is Test {
    EventFactory public factory;
    EventTicketing public ticketing;
    EventEscrow public escrow;

    address public creator = address(1);
    address public attendee = address(2);
    address public reseller = address(3);

    function setUp() public {
        factory = new EventFactory();
        ticketing = new EventTicketing(address(factory));
        escrow = new EventEscrow(address(factory));
    }

    function testCreateEvent() public {
        vm.startPrank(creator);
        uint256 eventId = factory.createEvent(
            "Test Event",
            1 ether,
            100,
            block.timestamp + 1 days,
            block.timestamp + 2 days,
            false,
            2 ether,
            true,
            1 hours
        );

        (
            address eventCreator,
            string memory metadata,
            uint256 ticketPrice,
            uint256 maxTickets,
            uint256 startTime,
            uint256 endTime,
            bool isVirtual,
            bool cancelled,
            ,
            ,
        ) = factory.events(eventId);

        assertEq(eventCreator, creator);
        assertEq(metadata, "Test Event");
        assertEq(ticketPrice, 1 ether);
        assertEq(maxTickets, 100);
        assertTrue(!cancelled);
        vm.stopPrank();
    }

    function testMintTicket() public {
        vm.startPrank(creator);
        uint256 eventId = factory.createEvent(
            "Test Event",
            1 ether,
            100,
            block.timestamp + 1 days,
            block.timestamp + 2 days,
            false,
            2 ether,
            true,
            1 hours
        );
        vm.stopPrank();

        vm.startPrank(attendee);
        vm.deal(attendee, 2 ether);
        uint256 ticketId = ticketing.mintTicket{value: 1 ether}(eventId);

        assertEq(ticketing.ownerOf(ticketId), attendee);

        (uint256 tEventId, uint256 ticketNumber, bool used,,,,) = ticketing.tickets(ticketId);
        assertEq(tEventId, eventId);
        assertEq(ticketNumber, 0);
        assertTrue(!used);
        vm.stopPrank();
    }

    function testTicketResale() public {
        // Create event
        vm.startPrank(creator);
        uint256 eventId = factory.createEvent(
            "Test Event",
            1 ether,
            100,
            block.timestamp + 1 days,
            block.timestamp + 2 days,
            false,
            2 ether,
            true,
            1 hours
        );
        vm.stopPrank();

        // Mint ticket
        vm.startPrank(reseller);
        vm.deal(reseller, 2 ether);
        uint256 ticketId = ticketing.mintTicket{value: 1 ether}(eventId);

        // List for resale
        ticketing.listTicketForSale(ticketId, 1.5 ether);
        vm.stopPrank();

        // Buy resale ticket
        vm.startPrank(attendee);
        vm.deal(attendee, 2 ether);
        ticketing.buyResaleTicket{value: 1.5 ether}(ticketId);

        assertEq(ticketing.ownerOf(ticketId), attendee);
        vm.stopPrank();
    }

    function testRefund() public {
        // Create event
        vm.startPrank(creator);
        uint256 eventId = factory.createEvent(
            "Test Event",
            1 ether,
            100,
            block.timestamp + 1 days,
            block.timestamp + 2 days,
            false,
            2 ether,
            true,
            1 hours
        );
        vm.stopPrank();

        // Mint ticket
        vm.startPrank(attendee);
        vm.deal(attendee, 2 ether);
        uint256 ticketId = ticketing.mintTicket{value: 1 ether}(eventId);

        uint256 balanceBefore = attendee.balance;
        ticketing.refundTicket(ticketId);
        uint256 balanceAfter = attendee.balance;

        assertEq(balanceAfter - balanceBefore, 1 ether);
        vm.expectRevert(); // Expect revert when trying to access burned ticket
        ticketing.ownerOf(ticketId);
        vm.stopPrank();
    }

    function testFailMintAfterStart() public {
        vm.startPrank(creator);
        uint256 eventId = factory.createEvent(
            "Test Event",
            1 ether,
            100,
            block.timestamp + 1 days,
            block.timestamp + 2 days,
            false,
            2 ether,
            true,
            1 hours
        );
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(attendee);
        vm.deal(attendee, 2 ether);
        ticketing.mintTicket{value: 1 ether}(eventId);
        vm.stopPrank();
    }

    function testFailResaleAboveMax() public {
        vm.startPrank(creator);
        uint256 eventId = factory.createEvent(
            "Test Event",
            1 ether,
            100,
            block.timestamp + 1 days,
            block.timestamp + 2 days,
            false,
            2 ether,
            true,
            1 hours
        );
        vm.stopPrank();

        vm.startPrank(reseller);
        vm.deal(reseller, 2 ether);
        uint256 ticketId = ticketing.mintTicket{value: 1 ether}(eventId);

        ticketing.listTicketForSale(ticketId, 3 ether); // Should fail
        vm.stopPrank();
    }
}
