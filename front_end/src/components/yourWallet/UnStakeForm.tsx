import React, { useState, useEffect } from "react"
import { Token } from "../Main"
import { useEthers, useTokenBalance, useNotifications } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { Button, Input, CircularProgress, Snackbar } from "@material-ui/core"
import Alert from "@material-ui/lab/Alert"
import { useUnStakeTokens } from "../../hooks"
import { utils } from "ethers"

export interface UnStakeFormProps {
    token: Token
}

export const UnStakeForm = ({ token }: UnStakeFormProps) => {
    const { address: tokenAddress, name } = token

    const { UnStake, mystate } = useUnStakeTokens(tokenAddress)
    const handleUnStakeSubmit = () => {
        return UnStake()
    }


    //console.log(mystate.status)
    const isMiningUnstake = mystate.status === "Mining"

    return (
        <>
            <div>
                <Button
                    onClick={handleUnStakeSubmit}
                    color="primary"
                    size="small"
                    disabled={isMiningUnstake}>
                    {isMiningUnstake ? <CircularProgress size={26} /> : "从交易池取出余额"}
                </Button>
            </div>
        </>
    )
}
