import { Token } from "../Main"
import { useEthers, useTokenBalance, useContractCall } from "@usedapp/core"
import { Content2Msg } from "../Content2Msg"


import { constants, utils } from "ethers"
import TokenFarm from "../../chain-info/contracts/TokenFarm.json"
import networkMapping from "../../chain-info/deployments/map.json"

export interface WhenExpiryProps {
    token: Token
}

export const WhenExpiry = ({ token }: WhenExpiryProps) => {
    const { chainId, account } = useEthers()
    const { abi } = TokenFarm
    const tokenFarmAddress = chainId ? networkMapping[String(chainId)]["TokenFarm"][0] : constants.AddressZero
    const tokenFarmInterface = new utils.Interface(abi)

    const [secondsToExpiry] =
        useContractCall(
            tokenFarmAddress && {
                abi: tokenFarmInterface, // ABI interface of the called contract
                address: tokenFarmAddress, // On-chain address of the deployed contract
                method: "SecondToExpiry", // Method to be called
                args: [], // Method arguments - address to be checked for balance
            }
        ) ?? [];
    //console.log("secondsToExpiry:", secondsToExpiry)

    return (<Content2Msg
        label={'还有' + (secondsToExpiry / 60 / 60).toFixed(1) + `小时到期`} />)

}
