// SPDX-License-Identifier: MIT
pragma solidity >0.6.7;

contract insert {
    uint256[] public bid = [12, 10, 8, 6];
    uint256 public newbid;
    uint256 public mid;

    function add(uint256 _new) public {
        newbid = _new;
        bid.push(_new);
    }

    function pop() public {
        bid.pop();
    }

    function del(uint256 index) public {
        delete bid[index];
    }

    function getlen() public view returns (uint256) {
        return (bid.length);
    }

    function addit(uint256 _new) public returns (uint256[] memory) {
        uint256 left = 0;
        uint256 right = bid.length - 1;
        newbid = _new;

        // binary tree insert
        while (left < right) {
            mid = (left + right) / 2;
            if (newbid > bid[mid]) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }
        // loop ends: if left > right mid is correct position; if left == right, need to compare with right
        if (left == right) {
            if (newbid > bid[left]) {
                mid = left;
            } else {
                mid = left + 1;
            }
        }
        // push the new bid into the sorted array
        if (mid == bid.length) {
            bid.push(newbid);
        } else {
            bid.push(0); //bid length increased 1 here
            for (uint256 i = bid.length - 1; i > mid; i--) {
                bid[i] = bid[i - 1];
            }
            bid[mid] = newbid;
        }
        return bid;
    }
}
