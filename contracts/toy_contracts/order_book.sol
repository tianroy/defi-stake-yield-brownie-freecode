// SPDX-License-Identifier: MIT
pragma solidity >0.6.7;

contract insert {
    //uint256[] public bid = [12,10,8,6];
    uint256 public newbid;
    uint256 public mid;
    struct bid_struct {
        uint256 price_percent;
        uint256 amount;
    }
    bid_struct[] public bids;
    uint256[] public bid_order = [2, 3, 0, 1];

    uint256 public supply = 18000;

    constructor() {
        bids.push(bid_struct(10, 2000));
        bids.push(bid_struct(12, 1000));
        bids.push(bid_struct(6, 10000));
        bids.push(bid_struct(8, 5000));
    }

    function averageBid(uint256 ask_size)
        public
        view
        returns (uint256 average_bid)
    {
        require(ask_size >= 1000, "min size = 1000");
        require(ask_size <= supply, "not enough supply");
        uint256 _size = ask_size;
        uint256 _sizexprice = 0;
        uint256 i = bid_order.length - 1;
        while (_size > 0) {
            if (_size >= bids[bid_order[i]].amount) {
                _sizexprice += (bids[bid_order[i]].amount *
                    bids[bid_order[i]].price_percent);
                _size = _size - bids[bid_order[i]].amount;
            } else {
                _sizexprice += (_size * bids[bid_order[i]].price_percent);
                _size = 0;
            }
            i--;
        }
        average_bid = _sizexprice / ask_size;
        return average_bid;
    }

    function sellBid(uint256 ask_size) public returns (uint256 average_bid) {
        require(ask_size >= 1000, "min size = 1000");
        require(ask_size <= supply, "not enough supply");
        uint256 _size = ask_size;
        uint256 _sizexprice = 0;
        uint256 i = bid_order.length - 1;
        while (_size > 0) {
            if (_size >= bids[bid_order[i]].amount) {
                _sizexprice += (bids[bid_order[i]].amount *
                    bids[bid_order[i]].price_percent);
                _size -= bids[bid_order[i]].amount;
                supply -= bids[bid_order[i]].amount;
                bids[bid_order[i]].amount = 0;
                // last one is the highest one, pop the highest bid
                bid_order.pop();
            } else {
                _sizexprice += (_size * bids[bid_order[i]].price_percent);
                bids[bid_order[i]].amount -= _size;
                supply -= _size;
                _size = 0;
            }
            i--;
        }
        average_bid = _sizexprice / ask_size;
        return average_bid;
    }

    function addBid(uint256 _new) public returns (uint256[] memory) {
        uint256 left = 0;
        uint256 right = bid_order.length - 1;
        newbid = _new;
        bids.push(bid_struct(newbid, 5000));
        supply += 5000;

        // binary tree insert
        while (left < right) {
            mid = (left + right) / 2;
            if (newbid > bids[bid_order[mid]].price_percent) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        // when loop ends:
        // if left > right mid is correct position to insert
        // if left == right, need to compare once more with right
        if (left == right) {
            if (newbid > bids[bid_order[left]].price_percent) {
                mid = left + 1;
            } else {
                mid = left;
            }
        }
        // push the new bid into the bid_order array
        bid_order.push(bid_order.length); //bid length is increasing 1 here
        if (mid < bid_order.length - 1) {
            for (uint256 i = bid_order.length - 1; i > mid; i--) {
                bid_order[i] = bid_order[i - 1];
            }
            bid_order[mid] = bid_order.length - 1; // bid length has increased 1 earlier
        } // else if mid == bid_order.lenghth, newbid is highest and already been pushed to the last one of bid_order
        return bid_order;
    }

    function getBidOrder() public view returns (uint256[] memory) {
        return bid_order;
    }

    function getBids() public view returns (bid_struct[] memory) {
        return bids;
    }

    function getlen() public view returns (uint256) {
        return (bid_order.length);
    }
}
