// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
@title ToPack - The new era of private, secure, and fast delivery
@dev Makes sure the payment takes place once the pack has been delivered
 */

contract Pack{

    /// @notice Structure of each shipping
    struct Box {
        uint256 boxID;  
        address senderAddr; 
        address travellerAddr;
        address receiverAddr;
        uint256 shippingCost;
        uint256 boxValue;
    }

    /// @notice Contract deployment
    constructor()  {
        minter = payable(msg.sender);         // saving the minter address
    }

    /// @notice Counter that acts as a unique identifier for each shipping
    uint256 currentBoxID;
    /// @notice Array that stores each shipping of a user as a sender
    mapping(address => Box[]) public sentMap;
    /// @notice Array that stores each shipping of a user as a traveller
    mapping(address => Box[]) public travelMap;
    /// @notice Array that stores all the shippings in process
    mapping (uint256 => Box) public boxes;    
    /// @notice Address of the minter for the withdraw
    address payable minter;

    /**
    @notice Creation of the non-fungible token that works as a receipt
    @param _senderAddr Address of the sender
    @param _travellerAddr Address of the traveller
    @param _receiverAddr Address of the receiver
    @param _shippingCost Shipment cost
    @param _boxValue Pack value
     */
    function assignBox(
        address _senderAddr,
        address _travellerAddr,
        address _receiverAddr,
        uint256 _shippingCost,
        uint256 _boxValue
    ) public {
        // Temporary box created
        Box memory newBox = Box({boxID: currentBoxID, senderAddr: _senderAddr, 
            travellerAddr: _travellerAddr, receiverAddr: _receiverAddr, shippingCost: _shippingCost, boxValue: _boxValue});
        // Push of the shipping inside the respective mappings
        sentMap[_senderAddr].push(newBox);
        travelMap[_travellerAddr].push(newBox);
        boxes[currentBoxID] = newBox;
        // currentBoxID increased for the next shipping
        currentBoxID = currentBoxID +1;
    }

    /**
    @notice Inform of the value of a pack
    @param _boxID ID that refers to the shipping
    @return _boxValue Value of the pack of the shipping
    */
    function deliverBox(
        uint256 _boxID
        ) public view returns (uint256 _boxValue){
        return boxes[_boxID].boxValue;
    }

    /**
    @notice List all the shippings assigned to the sender
    @param _senderAddr Address of the user
    @return se Shippings as a sender
     */
    function getUserBox(address _senderAddr)  public view returns (Box[] memory se){
        // get the list of posts created by the msg.sender
        return  sentMap[_senderAddr];
    }
    
    /**
    @notice List all the shippings assigned to the traveller
    @param _travellerAddr Address of the user
    @return tr Shippings as a traveller
     */
    function getTravellerBoxes(address _travellerAddr)  public view returns (Box[] memory tr){
        // get the list of posts created by the msg.sender
        return  travelMap[_travellerAddr];
    }

    /**
    @notice Unlock the money that has been sent to the contract and pay the traveller
    @param _boxID ID that refers to the shipping
    */
    function boxDelivered(uint _boxID) public{
        // only the receiver can call this function to pay the traveller
        require(msg.sender == boxes[_boxID].receiverAddr);

        // paying the traveller from the smart contract, giving him back the boxValue too
        payable(boxes[_boxID].travellerAddr).transfer(boxes[_boxID].shippingCost);  //  paying for the shipping
        payable(boxes[_boxID].travellerAddr).transfer(boxes[_boxID].boxValue);      //  giving back the box value

        // temporary aliases for the addresses
        address sender = boxes[_boxID].senderAddr;
        address traveller = boxes[_boxID].travellerAddr;  

        // burn the nfts   
        burn(sender,traveller, _boxID);
    }

    /**
    @notice Burn the non-fungible tokens created for this pack
    @param sender Address of the sender
    @param traveller Address of the traveller
    @param _boxID ID that refers to the shipping
    */
    function burn(address sender, address traveller, uint256 _boxID) private {
        // delete the box from the sender array
        // if the _boxID is the ID of the last item in the map, just pop it
        if (sender == boxes[_boxID].senderAddr) {
            if (_boxID == (sentMap[sender][(sentMap[sender]).length - 1].boxID)) {
                sentMap[sender].pop();
            }
            // if _boxID is the ID of the first (and the only) box in the array
            else if (
                (sentMap[sender]).length == 1 && _boxID == sentMap[sender][0].boxID
            ) {
                sentMap[sender].pop();
            } else if ((sentMap[sender]).length != 1) {
                // move the element as last element of the array and then delete it
                for (uint256 i = 0; i < (sentMap[sender]).length; i++) {
                    if (_boxID == sentMap[sender][i].boxID) {
                        sentMap[sender][i] = sentMap[sender][
                            (sentMap[sender]).length - 1
                        ];
                        sentMap[sender].pop();
                        break;
                    }
                }
            }
        }
        // delete the box from the travelelr map
        if (traveller == boxes[_boxID].travellerAddr) {
            if (
                _boxID == (travelMap[traveller][(travelMap[traveller]).length - 1].boxID)
            ) {
                travelMap[traveller].pop();
            } else if (
                (travelMap[traveller]).length == 1 &&
                _boxID == travelMap[traveller][0].boxID
            ) {
                travelMap[traveller].pop();
            } else if ((travelMap[traveller]).length != 1) {
                for (uint256 i = 0; i < (travelMap[traveller]).length; i++) {
                    if (_boxID == travelMap[traveller][i].boxID) {
                        travelMap[traveller][i] = travelMap[traveller][
                            (travelMap[traveller]).length - 1
                        ];
                        travelMap[traveller].pop();
                        break;
                    }
                }
            }
        }
        // delete the element from the map of the boxes
        delete boxes[_boxID];
    }

    /// @notice Money has been received by the contract
    event Received(address, uint);

    /// @notice Receive function used to receive ether
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
