// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./EventFactory.sol";
import "./Base64.sol";

contract EventTicketing is ERC721URIStorage, ReentrancyGuard, Ownable {
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
    event BaseURIUpdated(string oldBaseURI, string newBaseURI);

    constructor(address _eventFactory) 
        ERC721("Event Ticket", "TCKT") 
        Ownable(msg.sender) 
    {
        eventFactory = EventFactory(_eventFactory);
    }

    function updateTicketBaseURI(string memory newBaseURI) external onlyOwner {
        emit BaseURIUpdated(baseURI, newBaseURI);
        baseURI = newBaseURI;
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

    function refundTicket(uint256 _ticketId) external nonReentrant {
        require(ownerOf(_ticketId) == msg.sender, "Not ticket owner");
        
        Ticket storage ticket = tickets[_ticketId];
        require(!ticket.used, "Ticket already used");
        
        EventFactory.Event memory event_ = eventFactory.getEvent(ticket.eventId);
        require(!event_.cancelled, "Event already cancelled");
        require(block.timestamp < event_.startTime, "Event already started");
        
        uint256 refundAmount = ticket.purchasePrice;
        
        // Burn the ticket first
        _burn(_ticketId);
        
        // Then send the refund
        payable(msg.sender).transfer(refundAmount);
        
        emit TicketRefunded(_ticketId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        try this.ownerOf(tokenId) returns (address owner) {
            require(owner != address(0), "Token does not exist");
        } catch {
            revert("Token does not exist");
        }

        Ticket memory ticket = tickets[tokenId];
        EventFactory.Event memory event_ = eventFactory.getEvent(ticket.eventId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name":"Event Ticket #', Strings.toString(ticket.ticketNumber),
                '","description":"Ticket for Event #', Strings.toString(ticket.eventId),
                '","attributes":[{"trait_type":"Event ID","value":', Strings.toString(ticket.eventId),
                '},{"trait_type":"Used","value":', ticket.used ? "true" : "false",
                '},{"trait_type":"Purchase Price","value":', Strings.toString(ticket.purchasePrice),
                '}]}'
            )
        );

        return string(
            abi.encodePacked(
                baseURI,
                "data:application/json;base64,",
                Base64.encode(bytes(metadata))
            )
        );
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

    function listTicketForSale(uint256 _ticketId, uint256 _price) external {
        require(ownerOf(_ticketId) == msg.sender, "Not ticket owner");
        
        Ticket storage ticket = tickets[_ticketId];
        require(!ticket.used, "Ticket already used");

        EventFactory.Event memory event_ = eventFactory.getEvent(ticket.eventId);
        require(_price <= event_.maxResalePrice, "Price above max resale price");
        
        ticket.forSale = true;
        ticket.resalePrice = _price;

        emit TicketListedForSale(_ticketId, _price);
    }

    function buyTicket(uint256 _ticketId) external payable nonReentrant {
        Ticket storage ticket = tickets[_ticketId];
        require(ticket.forSale, "Ticket not for sale");
        require(msg.value >= ticket.resalePrice, "Insufficient payment");

        address previousOwner = ownerOf(_ticketId);
        address newOwner = msg.sender;

        _transfer(previousOwner, newOwner, _ticketId);

        payable(previousOwner).transfer(msg.value);

        ticket.forSale = false;
        ticket.resalePrice = 0;

        emit TicketSold(_ticketId, newOwner, msg.value);
    }

    function checkTokenExists(uint256 tokenId) internal view returns (bool) {
        try this.ownerOf(tokenId) returns (address owner) {
            return owner != address(0);
        } catch {
            return false;
        }
    }
}