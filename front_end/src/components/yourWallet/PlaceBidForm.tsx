import React, { useState, useEffect } from "react"
import { Token } from "../Main"
import { useEthers, useTokenBalance, useNotifications } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { Button, Input, CircularProgress, Snackbar } from "@material-ui/core"
import Alert from "@material-ui/lab/Alert"
import { usePlaceBid } from "../../hooks"
import { utils } from "ethers"

export interface PlaceBidFormProps {
    token: Token
}


export const PlaceBidForm = ({ token }: PlaceBidFormProps) => {
    const { address: tokenAddress, name } = token
    const { account } = useEthers()
    const tokenBalance = useTokenBalance(tokenAddress, account)
    const formattedTokenBalance: number = tokenBalance ? parseFloat(formatUnits(tokenBalance, 18)) : 0
    const { notifications } = useNotifications()

    const [amount, setAmount] = useState<number>(0)
    const [premium, setPremium] = useState<number>(0)

    const { PlaceBid, mystate } = usePlaceBid(amount, premium)
    const handlePlaceBid = () => {
        return PlaceBid()
    }


    const handleAmountChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        const newAmount = (event.target.value === "") ? 0 : Number(event.target.value)
        // TODO: @henry add .....
        setAmount(newAmount)
        //console.log('PlaceBidForm.newAmount', newAmount)
    }
    const handlePremiumChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        const newPremium = event.target.value === "" ? 0 : Number(event.target.value)
        setPremium(newPremium)
        //console.log('PlaceBidForm.newPremium', newPremium)
    }



    console.log(mystate)
    const isMiningUnstake = mystate.status === "Mining"

    return (
        <>
            <div>
                <Input
                    onChange={handleAmountChange} />
                <Input
                    onChange={handlePremiumChange} />
                <Button
                    onClick={handlePlaceBid}
                    color="primary"
                    size="small"
                    disabled={isMiningUnstake}>
                    {isMiningUnstake ? <CircularProgress size={26} /> : "input price/option and total premium"}
                </Button>
            </div>
        </>
    )
}