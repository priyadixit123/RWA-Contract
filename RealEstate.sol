// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RealEstate {
    struct Property {
        uint256 id;
        string location;
        uint256 price;
        address owner;
        bool forSale;
    }

    uint256 public propertyCount;
    mapping(uint256 => Property) public properties;
    mapping(address => uint256[]) public ownerProperties;

    event PropertyRegistered(uint256 propertyId, address indexed owner);
    event OwnershipTransferred(uint256 propertyId, address indexed newOwner);
    event PropertyListed(uint256 propertyId, uint256 price);
    event PropertyDelisted(uint256 propertyId);

    modifier onlyOwner(uint256 propertyId) {
        require(
            properties[propertyId].owner == msg.sender,
            "Not the property owner"
        );
        _;
    }

    modifier propertyExists(uint256 propertyId) {
        require(
            properties[propertyId].owner != address(0),
            "Property does not exist"
        );
        _;
    }

    function registerProperty(string memory _location, uint256 _price)
        external
    {
        require(_price > 0, "Price must be greater than zero");
        propertyCount++;

        properties[propertyCount] = Property({
            id: propertyCount,
            location: _location,
            price: _price,
            owner: msg.sender,
            forSale: false
        });

        ownerProperties[msg.sender].push(propertyCount);

        emit PropertyRegistered(propertyCount, msg.sender);
    }

    function listProperty(uint256 propertyId, uint256 _price)
        external
        onlyOwner(propertyId)
        propertyExists(propertyId)
    {
        require(_price > 0, "Price must be greater than zero");

        properties[propertyId].price = _price;
        properties[propertyId].forSale = true;

        emit PropertyListed(propertyId, _price);
    }

    function delistProperty(uint256 propertyId)
        external
        onlyOwner(propertyId)
        propertyExists(propertyId)
    {
        properties[propertyId].forSale = false;

        emit PropertyDelisted(propertyId);
    }

    function purchaseProperty(uint256 propertyId)
        external
        payable
        propertyExists(propertyId)
    {
        Property storage property = properties[propertyId];

        require(property.forSale, "Property is not for sale");
        require(msg.value == property.price, "Incorrect payment amount");

        address previousOwner = property.owner;

        // Update ownership
        property.owner = msg.sender;
        property.forSale = false;

        // Update owner's property list
        _removePropertyFromOwner(previousOwner, propertyId);
        ownerProperties[msg.sender].push(propertyId);

        // Transfer funds
        payable(previousOwner).transfer(msg.value);

        emit OwnershipTransferred(propertyId, msg.sender);
    }

    function getPropertiesByOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return ownerProperties[owner];
    }

    function _removePropertyFromOwner(address owner, uint256 propertyId)
        internal
    {
        uint256[] storage propertiesOwned = ownerProperties[owner];
        for (uint256 i = 0; i < propertiesOwned.length; i++) {
            if (propertiesOwned[i] == propertyId) {
                propertiesOwned[i] = propertiesOwned[propertiesOwned.length - 1];
                propertiesOwned.pop();
                break;
            }
        }
    }
}
