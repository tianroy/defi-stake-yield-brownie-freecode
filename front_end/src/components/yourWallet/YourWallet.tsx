import { Token } from "../Main"
import React, { useState } from "react"
import { Box, makeStyles } from "@material-ui/core"
import { TabContext, TabList, TabPanel } from "@material-ui/lab"
import { Tab } from "@material-ui/core"
import { WalletBalance } from "./WalletBalance"
import { StakeForm } from "./StakeForm"
import { UnStakeForm } from "./UnStakeForm"
import { platform } from "os"
import { PlaceBidForm } from "./PlaceBidForm"
import { SellBidForm } from "./SellBidForm"
import { OptionSupply } from "./OptionSupply"
import { CancelBidForm } from "./CancelBidForm"
import { ExerciseForm } from "./ExerciseForm"
import { UnusedPremium } from "./UnusedPremium"
import { WhenExpiry } from "./WhenExpiry"
import { UserSize } from "./UserSize"
import { EthPrice } from "./EthPrice"
import { BestBid } from "./BestBid"
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

            <h2 className={classes.header}> 请在交易池中存有足够USDx余额 </h2>
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
            <h2 className={classes.header}> ETH双币理财 挂钩价3300</h2>
            <Box>
                <Box className={classes.box}>
                    <div className={classes.tabContent}>
                        <BestBid token={supportedTokens[selectedTokenIndex]} />
                        <SellBidForm token={supportedTokens[selectedTokenIndex]} />
                        <OptionSupply token={supportedTokens[selectedTokenIndex]} />
                        <WhenExpiry token={supportedTokens[selectedTokenIndex]} />
                        <EthPrice token={supportedTokens[selectedTokenIndex]} />
                        <UserSize token={supportedTokens[selectedTokenIndex]} />
                        <ExerciseForm token={supportedTokens[selectedTokenIndex]} />
                    </div>
                </Box>
            </Box>
            <h3 className={classes.header}> market maker portal</h3>
            <Box>
                <Box className={classes.box}>
                    <div className={classes.tabContent}>
                        <PlaceBidForm token={supportedTokens[selectedTokenIndex]} />
                        <UnusedPremium token={supportedTokens[selectedTokenIndex]} />
                        <CancelBidForm token={supportedTokens[selectedTokenIndex]} />
                    </div>
                </Box>
            </Box>

        </Box >
    )

}
