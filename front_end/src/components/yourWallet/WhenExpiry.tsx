import { Token } from "../Main"
import { useEthers, useTokenBalance, useContractCall } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { BalanceMsg } from "../BalanceMsg"

import { constants, utils } from "ethers"
import TokenFarm from "../../chain-info/contracts/TokenFarm.json"
import networkMapping from "../../chain-info/deployments/map.json"

export interface WhenExpiryProps {
    token: Token
}

export const WhenExpiry = ({ token }: WhenExpiryProps) => {
    // address
    // abi
    // chainId
    const { chainId, account } = useEthers()
    const { abi } = TokenFarm
    const tokenFarmAddress = chainId ? networkMapping[String(chainId)]["TokenFarm"][0] : constants.AddressZero
    const tokenFarmInterface = new utils.Interface(abi)
    const { image, address, name } = token

    const [secondsToExpiry] =
        useContractCall(
            //account &&
            tokenFarmAddress && {
                abi: tokenFarmInterface, // ABI interface of the called contract
                address: tokenFarmAddress, // On-chain address of the deployed contract
                method: "SecondToExpiry", // Method to be called
                args: [], // Method arguments - address to be checked for balance
            }
        ) ?? [];
    console.log("account:", secondsToExpiry)
    //debugger;

    return (<BalanceMsg
        label={`expiry day`}
        tokenImgSrc={image}
        amount={Number(secondsToExpiry)} />)

}
