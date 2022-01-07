//备注1 所有 .size 的单位是 有多少张option x strike
//备注2 bids记录了这个option所有曾经的bid 也包括已经卖掉或者取消的；bid.order指针有序的维护所有可以被sell的bid
//备注3 user.size是seller sell了这个buyer多少size

// 首先market maker 提供bid before seller can sellBid
function placeBid(uint256 newbid, uint256 premium) public {
    // buyer place bid order but nothing traded yet

    // update buyer
    // btw user.size only updated when seller sell the bid / only when trade
    //user.unusedpremium 是放出了多少bid 但还没有交易
    user[_user][id].unusedpremium += premium; //premium not used if seller not selling it
    cash_balance[_user] -= premium;

    // update option supply
    //size 参考备注1
    uint256 _size = (premium * op[id].strike) / newbid;
    op[id].supply += _size;

    // update order book
    bids[id].push(bid_struct(newbid, _size, _user));
    //bids.length - 1 是现在这个bid的指针位置
    //op.bid是一个有序的指针序列 op.bid[0]永远是最小的bid
    if (op[id].order.length == 0) {
        op[id].order.push(bids[id].length - 1);
    } else {
        // 按newbid的大小插入op.order序列
        insertBid(newbid); //insertBid是pure fuction
    }
}

function cancelBid() public {
    //取消这位买家的全部bid
    // to make it easy, cancel all bids for testing stage
    // update buyer
    // 把还没交易的premium还给现金账户 并把unusedpremium清零
    cash_balance[_user] += user[_user][id].unusedpremium;
    user[_user][id].unusedpremium = 0;

    // update order book and option supply
    // 把所有属于这个user的bid都从op.order中删掉，同时把seller可以卖掉的op.supply分别降低
    uint256[] memory old_order = op[id].order;
    uint256 k = 0;
    for (uint256 i = 0; i < old_order.length; i++) {
        if (bids[id][old_order[i]].user_id != _user) {
            // if this bid is not from this user
            op[id].order[k] = old_order[i];
            // k = how many bids we need to keep
            k++;
        } else {
            op[id].supply -= bids[id][old_order[i]].size;
        }
    }
    // 这里op.order长度会变短 但是 bids不会
    for (uint256 i = 0; i < old_order.length - k; i++) {
        op[id].order.pop();
    }
}

function sellBid(uint256 seller_size) public {
    // seller size is in usd, full notional / collateral collected
    // seller option == buyer dual conntract!
    cash_balance[_user] -= seller_size;

    // update order book
    uint256 remain = seller_size;
    uint256 sizexprice = 0; //用来计算平均价格
    uint256 each_size;
    uint256 i = op[id].order.length - 1;
    // sell multiple bids to have enough size
    // 在seller_size范围内 从最高的bid 一级一级往下卖
    while (remain > 0) {
        each_size = bids[id][op[id].order[i]].size;
        if (remain >= each_size) {
            // update buyer
            //记录买家交易size
            user[bids[id][op[id].order[i]].user_id][id].size += each_size;
            //买家的premium不可以再取回from cancelBid
            user[bids[id][op[id].order[i]].user_id][id]
                .unusedpremium -= ((each_size *
                bids[id][op[id].order[i]].price) / op[id].strike);
            // update seller
            sizexprice += (each_size * bids[id][op[id].order[i]].price); // 为了计算平均价
            // update option
            // 把这个bid supply减少
            op[id].supply -= each_size;
            // update order book
            bids[id][op[id].order[i]].size = 0; //这行不是一定需要，因为这个bid指针会被删除
            // last one is the highest one, pop the highest bid
            // 删除最贵的bid指针
            op[id].order.pop();
            remain -= each_size;
        } else {
            // update buyer
            // 逻辑类似 但是这个bidm没有完全被拿走，指针还存在，只是size变少
            user[bids[id][op[id].order[i]].user_id][id].size += remain;
            user[bids[id][op[id].order[i]].user_id][id]
                .unusedpremium -= ((remain * bids[id][op[id].order[i]].price) /
                op[id].strike);
            // update seller
            sizexprice += (remain * bids[id][op[id].order[i]].price);
            // update option
            op[id].supply -= remain;
            // update order book
            bids[id][op[id].order[i]].size -= remain;
            remain = 0;
        }
        i--;
    }
    // update seller
    getEthPrice();
    //expiry = (sizexprice / seller_size / ethPrice + 1 )x seller_size
    // 这是平均回报率=sizexprice / seller_size / ethPrice，所以以下就是expiry要给的size
    user[_user][id].size += ((sizexprice + seller_size * ethPrice) / ethPrice);
}

function getBestBid(uint256 seller_size)
    public
    view
    returns (uint256 average_bid)
{
    // same logic as sellOption Function but not updating options and users
    average_bid = sizexprice / seller_size;
    return average_bid;
}

function exercise() public {
    // for testing purpose please set a fake eth price
    // 如果买家还有未成交的bid/unusedpremium > 0 先执行cancelBid();

    if (_side == option_side.seller) {
        if (ethPrice < _strike) {
            // 卖家要拿到eth， 需要在这里转换eth，以下是eth size
            cash_balance[_user] += _size / _strike;
        } else {
            // 卖家，eth大于strike 要把cash和yield都还给卖家
            cash_balance[_user] += _size;
        }
    } else {
        if (ethPrice < _strike) {
            // 买家，现金settle，eth跌低于strike，买家赚钱
            cash_balance[_user] += ((_size * (_strike - ethPrice)) / _strike);
        } // else do nothing: expire worth zero
        // 买家 eth大于strike premium就没了 不退钱
    }
    user[_user][id].side = option_side.exercised;
}
