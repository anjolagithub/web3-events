pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./EventFactory.sol";

contract EventTicketing is ERC721, ReentrancyGuard {
    struct Ticket {
        uint256 eventId;
        uint256 ticketNumber;
        bool used;
        uint256 purchaseTime;
        uint256 purchasePrice;
        bool forSale;
        uint256 resalePrice;
    }

    EventFactory public eventFactory;
    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => uint256) public eventTicketCount;
    uint256 public nextTicketId;

    string public baseURI;

    event TicketMinted(uint256 indexed eventId, uint256 indexed ticketId);
    event TicketUsed(uint256 indexed ticketId);
    event TicketListedForSale(uint256 indexed ticketId, uint256 price);
    event TicketSold(uint256 indexed ticketId, address indexed buyer, uint256 price);
    event TicketRefunded(uint256 indexed ticketId);

    constructor(address _eventFactory) ERC721("Event Ticket", "TCKT") {
        eventFactory = EventFactory(_eventFactory);
    }

    function updateBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function mintTicket(uint256 _eventId) external payable nonReentrant returns (uint256) {
        EventFactory.Event memory event_ = eventFactory.getEvent(_eventId);
        require(!event_.cancelled, "Event cancelled");
        require(block.timestamp < event_.startTime, "Event started");
        require(eventTicketCount[_eventId] < event_.maxTickets, "Sold out");
        require(msg.value >= event_.ticketPrice, "Insufficient payment");

        uint256 ticketId = nextTicketId++;
        tickets[ticketId] = Ticket({
            eventId: _eventId,
            ticketNumber: eventTicketCount[_eventId]++,
            used: false,
            purchaseTime: block.timestamp,
            purchasePrice: event_.ticketPrice,
            forSale: false,
            resalePrice: 0
        });

        _mint(msg.sender, ticketId);
        emit TicketMinted(_eventId, ticketId);

        if (msg.value > event_.ticketPrice) {
            payable(msg.sender).transfer(msg.value - event_.ticketPrice);
        }

        return ticketId;
    }

    function listTicketForSale(uint256 _ticketId, uint256 _price) external {
        require(ownerOf(_ticketId) == msg.sender, "Not ticket owner");
        Ticket storage ticket = tickets[_ticketId];
        EventFactory.Event memory event_ = eventFactory.getEvent(ticket.eventId);

        require(event_.allowsResale, "Resale not allowed");
        require(_price <= event_.maxResalePrice, "Price exceeds max");
        require(!ticket.used, "Ticket used");
        require(block.timestamp < event_.startTime, "Event started");

        ticket.forSale = true;
        ticket.resalePrice = _price;
        emit TicketListedForSale(_ticketId, _price);
    }

    function buyResaleTicket(uint256 _ticketId) external payable nonReentrant {
        Ticket storage ticket = tickets[_ticketId];
        require(ticket.forSale, "Not for sale");
        require(msg.value >= ticket.resalePrice, "Insufficient payment");

        address seller = ownerOf(_ticketId);
        ticket.forSale = false;

        _transfer(seller, msg.sender, _ticketId);
        payable(seller).transfer(ticket.resalePrice);

        if (msg.value > ticket.resalePrice) {
            payable(msg.sender).transfer(msg.value - ticket.resalePrice);
        }

        emit TicketSold(_ticketId, msg.sender, ticket.resalePrice);
    }

    function refundTicket(uint256 _ticketId) external nonReentrant {
        require(ownerOf(_ticketId) == msg.sender, "Not ticket owner");
        Ticket storage ticket = tickets[_ticketId];
        EventFactory.Event memory event_ = eventFactory.getEvent(ticket.eventId);

        require(!ticket.used, "Ticket used");
        require(block.timestamp < event_.startTime, "Event started");
        require(block.timestamp <= ticket.purchaseTime + event_.refundWindow, "Refund window closed");

        ticket.used = true;
        _burn(_ticketId);
        payable(msg.sender).transfer(ticket.purchasePrice);

        emit TicketRefunded(_ticketId);
    }

    function useTicket(uint256 _ticketId) external {
        require(ownerOf(_ticketId) == msg.sender, "Not ticket owner");
        Ticket storage ticket = tickets[_ticketId];
        require(!ticket.used, "Ticket already used");

        EventFactory.Event memory event_ = eventFactory.getEvent(ticket.eventId);
        require(!event_.cancelled, "Event cancelled");
        require(block.timestamp >= event_.startTime, "Event not started");
        require(block.timestamp <= event_.endTime, "Event ended");

        ticket.used = true;
        emit TicketUsed(_ticketId);
    }
}
