import React, { useState, useEffect } from "react"
import { Token } from "../Main"
import { useEthers, useTokenBalance, useNotifications } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { Button, Input, CircularProgress, Snackbar } from "@material-ui/core"
import Alert from "@material-ui/lab/Alert"
import { useExercise } from "../../hooks"
import { utils } from "ethers"

export interface ExerciseFormProps {
    token: Token
}

export const ExerciseForm = ({ token }: ExerciseFormProps) => {
    const { address: tokenAddress, name } = token

    const { Exercise, mystate } = useExercise()
    const handleExercise = () => {
        return Exercise()
    }


    //console.log(mystate.status)
    const isMiningUnstake = mystate.status === "Mining"

    return (
        <>
            <div>
                <Button
                    onClick={handleExercise}
                    color="primary"
                    size="small"
                    disabled={isMiningUnstake}>
                    {isMiningUnstake ? <CircularProgress size={26} /> : "到期结算"}
                </Button>
            </div>
        </>
    )
}
