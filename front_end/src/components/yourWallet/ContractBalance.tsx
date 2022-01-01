import { Token } from "../Main"
import { useEthers, useTokenBalance } from "@usedapp/core"
import { formatUnits } from "@ethersproject/units"
import { BalanceMsg } from "../BalanceMsg"

import { constants, utils } from "ethers"
import TokenFarm from "../../chain-info/contracts/TokenFarm.json"
import networkMapping from "../../chain-info/deployments/map.json"

export interface ContractBalanceProps {
    token: Token
}

export const ContractBalance = ({ token }: ContractBalanceProps) => {
    const { chainId } = useEthers()
    const { abi } = TokenFarm
    const tokenFarmAddress = chainId ? networkMapping[String(chainId)]["TokenFarm"][0] : constants.AddressZero

    const { image, address, name } = token
    const tokenBalance = useTokenBalance(address, tokenFarmAddress)
    const formattedTokenBalance: number = tokenBalance ? parseFloat(formatUnits(tokenBalance, 18)) : 0
    return (<BalanceMsg
        label={`pool total ${name} balance`}
        tokenImgSrc={image}
        amount={formattedTokenBalance} />)
}
