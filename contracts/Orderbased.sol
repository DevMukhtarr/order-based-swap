// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OrderBasedSwap {
    address public owner;

    struct Order {
        address seller;        
        address offeredToken;  
        uint256 offeredAmount;  
        address requestedToken; 
        uint256 requestedAmount;
        bool fulfilled;         
    }

    modifier onlyOwner {
        require(msg.sender == owner, "you can't perform this action");
       _; 
    } 

    constructor (){
        owner = msg.sender;
    }

    uint256 public orderCount;
    mapping(uint256 => Order) public orders;

    event OrderCreated(
    uint256 orderId, 
    address seller, 
    address offeredToken,
    uint256 offeredAmount, 
    address requestedToken, 
    uint256 requestedAmount
    );
    event OrderFulfilled(uint256 orderId, address buyer, uint256 requestedAmount);

    function createOrder(
        address _offeredToken, 
        uint256 _offeredAmount, 
        address _requestedToken, 
        uint256 _requestedAmount
    ) external {
        require(_offeredAmount > 0, "Offered amount must be greater than zero");
        require(_requestedAmount > 0, "Requested amount must be greater than zero");

        IERC20(_offeredToken).transferFrom(msg.sender, address(this), _offeredAmount);

        orders[orderCount] = Order({
            seller: msg.sender,
            offeredToken: _offeredToken,
            offeredAmount: _offeredAmount,
            requestedToken: _requestedToken,
            requestedAmount: _requestedAmount,
            fulfilled: false
        });

        emit OrderCreated(
            orderCount, 
            msg.sender,
            _offeredToken,
            _offeredAmount,
            _requestedToken,
            _requestedAmount
             );
        orderCount++;
    }

    function fulfillOrder(uint256 _orderId) external {
        Order storage order = orders[_orderId];
        require(!order.fulfilled, "Order already fulfilled");
        require(order.seller != address(0), "Order does not exist");

        IERC20(order.requestedToken).transferFrom(msg.sender, order.seller, order.requestedAmount);

        IERC20(order.offeredToken).transfer(msg.sender, order.offeredAmount);

        order.fulfilled = true;

        emit OrderFulfilled(_orderId, msg.sender, order.requestedAmount);
    }

    function withdrawTokens(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }
}