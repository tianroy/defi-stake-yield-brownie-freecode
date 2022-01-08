import { Token } from "../Main"
import React, { useState } from "react"
import { Box, makeStyles } from "@material-ui/core"
import { TabContext, TabList, TabPanel } from "@material-ui/lab"
import { Tab } from "@material-ui/core"
import { WalletBalance } from "./WalletBalance"
import { StakeForm } from "./StakeForm"
import { UnStakeForm } from "./UnStakeForm"
import { ContractBalance } from "./ContractBalance"


interface YourWalletProps {
    supportedTokens: Array<Token>
}

const useStyles = makeStyles((theme) => ({
    tabContent: {
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: theme.spacing(4)
    },
    box: {
        display: "flex",
        flexDirection: "column",
        backgroundColor: "white",
        borderRadius: "25px",
        align: "center",
        justifyContent: 'center',
        margin: 'auto'
    },
    header: {
        color: "white"
    }
}))

export const YourWallet = ({ supportedTokens }: YourWalletProps) => {
    const [selectedTokenIndex, setSelectedTokenIndex] = useState<number>(0)

    const handleChange = (event: React.ChangeEvent<{}>, newValue: string) => {
        setSelectedTokenIndex(parseInt(newValue))
    }
    const classes = useStyles()
    return (
        <Box>
            <h2 className={classes.header}> First deposit your fund </h2>
            <Box className={classes.box}>
                <TabContext value={selectedTokenIndex.toString()}>
                    <TabList onChange={handleChange} aria-label="stake form tabs">
                        {supportedTokens.map((token, index) => {
                            return (
                                <Tab label={token.name}
                                    value={index.toString()}
                                    key={index} />
                            )
                        })}
                    </TabList>
                    {supportedTokens.map((token, index) => {
                        return (
                            <TabPanel value={index.toString()} key={index}>
                                <div className={classes.tabContent}>
                                    <WalletBalance token={supportedTokens[selectedTokenIndex]} />
                                    <StakeForm token={supportedTokens[selectedTokenIndex]} />
                                    <ContractBalance token={supportedTokens[selectedTokenIndex]} />
                                    <UnStakeForm token={supportedTokens[selectedTokenIndex]} />
                                </div>
                            </TabPanel>
                        )
                    })}
                </TabContext>
            </Box>
            <h2 className={classes.header}> you can buy Dual ETH Strike=4000 Maturity=2022-3-25 now</h2>
            <Box className={classes.box}>
                <WalletBalance token={supportedTokens[selectedTokenIndex]} />
                <StakeForm token={supportedTokens[selectedTokenIndex]} />
                <ContractBalance token={supportedTokens[selectedTokenIndex]} />
                <UnStakeForm token={supportedTokens[selectedTokenIndex]} />
            </Box>

        </Box >
    )

}
