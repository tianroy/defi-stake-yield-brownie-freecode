import React, { useState, useEffect } from "react"
import { Token } from "../Main"
import { useEthers, useTokenBalance, useNotifications } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { Button, Input, CircularProgress, Snackbar } from "@material-ui/core"
import Alert from "@material-ui/lab/Alert"
import { useSellBid } from "../../hooks"
import { utils } from "ethers"

export interface SellBidFormProps {
    token: Token
}


export const SellBidForm = ({ token }: SellBidFormProps) => {
    const { address: tokenAddress, name } = token
    const { account } = useEthers()
    const tokenBalance = useTokenBalance(tokenAddress, account)
    const formattedTokenBalance: number = tokenBalance ? parseFloat(formatUnits(tokenBalance, 18)) : 0
    const { notifications } = useNotifications()

    const [amount, setAmount] = useState<number>(0)

    const { SellBid, mystate } = useSellBid(amount)
    const handleSellBid = () => {
        return SellBid()
    }

    const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        const newAmount = event.target.value === "" ? 0 : Number(event.target.value)
        setAmount(newAmount)
    }


    console.log("sell bid state =", mystate)
    const isMiningUnstake = mystate.status === "Mining"



    return (
        <>
            <div>
                <Input
                    onChange={handleInputChange} />
                <Button
                    onClick={handleSellBid}
                    color="primary"
                    size="small"
                    disabled={isMiningUnstake}>
                    {isMiningUnstake ? <CircularProgress size={26} /> : "购买"}
                </Button>
            </div>
        </>
    )
}