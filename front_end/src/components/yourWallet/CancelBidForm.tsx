import React, { useState, useEffect } from "react"
import { Token } from "../Main"
import { useEthers, useTokenBalance, useNotifications } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { Button, Input, CircularProgress, Snackbar } from "@material-ui/core"
import Alert from "@material-ui/lab/Alert"
import { useCancelBid } from "../../hooks"
import { utils } from "ethers"

export interface CancelBidFormProps {
    token: Token
}

export const CancelBidForm = ({ token }: CancelBidFormProps) => {
    const { address: tokenAddress, name } = token

    const { CancelBid, mystate } = useCancelBid(tokenAddress)
    const handleCancelBidSubmit = () => {
        return CancelBid()
    }


    console.log(mystate)
    const isMiningCancelBid = mystate.status === "Mining"

    return (
        <>
            <div>
                <Button
                    onClick={handleCancelBidSubmit}
                    color="primary"
                    size="small"
                    disabled={isMiningCancelBid}>
                    {isMiningCancelBid ? <CircularProgress size={26} /> : "Cancel bid"}
                </Button>
            </div>
        </>
    )
}
