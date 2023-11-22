function AddRouteWithVpn([string]$name,[array]$params) {
    $vpnConn = Get-VpnConnection | Where-Object { $_.Name -eq $name -and $_.ConnectionStatus -eq "Connected" }
    Write-Host "found vpn $vpnConn"
    if ($vpnConn){
        foreach ($param in $params) {
            # 假设 vpn 适配器已经激活，尝试添加路由
            # 注意：你需要替换以下路由参数为你的实际需求
            # DestinationPrefix: 目标网络的前缀
            # NextHop: 下一跳地址（通常是网关地址）
            # （可选）Metric: 路由的度量值
            New-NetRoute -DestinationPrefix $param.DestinationPrefix -InterfaceAlias $name  -NextHop $vpnConn.ServerAddress -PolicyStore "ActiveStore"   -ErrorAction Stop
            if ($?) {
                Write-Host "路由已成功添加."
            }
        }
    }
}

function RemoveRouteWithVpn([array]$params) {
    foreach ($param in $params) {
        Remove-NetRoute -DestinationPrefix $param.DestinationPrefix
        if ($?) {
            Write-Host "路由已成功删除."
        }
    }
}

$routeParams = @(
    # gitlab
    @{
        DestinationPrefix = "10.64.46.0/24"
    },
    # 预发环境
    @{
        DestinationPrefix = "172.31.0.0/16"
    },
    #哈尔滨私有云星罗环境
    @{
        DestinationPrefix = "172.25.30.0/24"
    },
    # 哈尔滨打包环境
    @{
        DestinationPrefix = "172.25.6.44/32"
    }
)

AddRouteWithVpn "haerbin" $routeParams

RemoveRouteWithVpn $routeParams
