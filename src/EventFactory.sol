pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EventFactory is Ownable {
    struct Event {
        address creator;
        string metadata;
        uint256 ticketPrice;
        uint256 maxTickets;
        uint256 startTime;
        uint256 endTime;
        bool isVirtual;
        bool cancelled;
        uint256 maxResalePrice;
        bool allowsResale;
        uint256 refundWindow;
    }

    mapping(uint256 => Event) public events;
    uint256 public nextEventId;

    event EventCreated(uint256 indexed eventId, address indexed creator);
    event EventCancelled(uint256 indexed eventId);

    constructor() Ownable(msg.sender) {}

    function getEvent(uint256 eventId) external view returns (Event memory) {
        return events[eventId];
    }

    function createEvent(
        string memory _metadata,
        uint256 _ticketPrice,
        uint256 _maxTickets,
        uint256 _startTime,
        uint256 _endTime,
        bool _isVirtual,
        uint256 _maxResalePrice,
        bool _allowsResale,
        uint256 _refundWindow
    ) external returns (uint256) {
        require(_startTime > block.timestamp, "Invalid start time");
        require(_endTime > _startTime, "Invalid end time");
        require(_maxResalePrice >= _ticketPrice, "Invalid resale price");

        uint256 eventId = nextEventId++;
        events[eventId] = Event({
            creator: msg.sender,
            metadata: _metadata,
            ticketPrice: _ticketPrice,
            maxTickets: _maxTickets,
            startTime: _startTime,
            endTime: _endTime,
            isVirtual: _isVirtual,
            cancelled: false,
            maxResalePrice: _maxResalePrice,
            allowsResale: _allowsResale,
            refundWindow: _refundWindow
        });

        emit EventCreated(eventId, msg.sender);
        return eventId;
    }

    function cancelEvent(uint256 _eventId) external {
        Event storage event_ = events[_eventId];
        require(msg.sender == event_.creator, "Not event creator");
        require(!event_.cancelled, "Already cancelled");

        event_.cancelled = true;
        emit EventCancelled(_eventId);
    }
}
