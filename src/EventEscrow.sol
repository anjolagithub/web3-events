pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EventFactory} from "./EventFactory.sol";

contract EventEscrow is Ownable, ReentrancyGuard {
    EventFactory public eventFactory;
    mapping(uint256 => uint256) public eventBalance;

    event PaymentReleased(uint256 indexed eventId, address indexed recipient, uint256 amount);

    constructor(address _eventFactory) Ownable(msg.sender) {
        eventFactory = EventFactory(_eventFactory);
    }

    function depositEventPayment(uint256 _eventId) external payable {
        eventBalance[_eventId] += msg.value;
    }

    function releasePayment(uint256 _eventId) external nonReentrant {
        EventFactory.Event memory event_ = eventFactory.getEvent(_eventId);
        require(msg.sender == event_.creator, "Not event creator");
        require(block.timestamp > event_.endTime, "Event not ended");

        uint256 amount = eventBalance[_eventId];
        require(amount > 0, "No balance");

        eventBalance[_eventId] = 0;
        payable(event_.creator).transfer(amount);

        emit PaymentReleased(_eventId, event_.creator, amount);
    }
}
