-- LocalScript

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rs = game:GetService("RunService")
local players = game:GetService("Players")
local teleportDistance = 20
local maxTeleportDistance = 25 -- Distância para considerar teletransporte
local followSpeed = 30 -- Velocidade de movimento suave
local teleportCooldown = 0.5 -- Tempo em segundos entre teletransportes
local distanceFromTarget = 10 -- Distância atrás do inimigo para seguir

local lastTeleportTime = 0
local lastUpdate = tick()
local updateInterval = 0.1 -- Intervalo de atualização em segundos

-- Função para verificar se dois jogadores são da mesma equipe
local function sameTeam(player1, player2)
    if player1.Team and player2.Team then
        return player1.Team == player2.Team
    end
    return false
end

-- Função para usar tgoto para mover rapidamente
local function tgoto(targetPosition)
    local myHumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not myHumanoidRootPart then return end

    -- Usar tgoto para teleportar rapidamente
    myHumanoidRootPart.CFrame = CFrame.new(targetPosition)
end

-- Função para seguir o alvo mantendo uma distância estratégica atrás dele
local function followBehind(targetPosition)
    local myHumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local targetHumanoidRootPart = game.Players:GetPlayerFromCharacter(targetPosition):FindFirstChild("HumanoidRootPart")
    if not myHumanoidRootPart or not targetHumanoidRootPart then return end

    -- Calcular a direção para se mover atrás do alvo
    local direction = (myHumanoidRootPart.Position - targetHumanoidRootPart.Position).unit
    local behindPosition = targetHumanoidRootPart.Position + direction * distanceFromTarget

    -- Mover suavemente para a posição calculada usando tgoto
    tgoto(behindPosition)
    myHumanoidRootPart.CFrame = CFrame.new(behindPosition, targetHumanoidRootPart.Position) -- Olhar para o alvo
end

-- Função para teletransportar o jogador para uma posição atrás de um alvo e olhar para ele
local function teleportToBehind(targetPlayer)
    local targetCharacter = targetPlayer.Character
    if not targetCharacter or not targetCharacter:FindFirstChild("Humanoid") or targetCharacter.Humanoid.Health <= 0 then
        return -- Não teletransportar se o alvo estiver morto
    end

    -- Verificar se o jogador alvo é da mesma equipe
    if sameTeam(player, targetPlayer) then
        return -- Não teletransportar para colegas de equipe
    end

    local targetHumanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    local myHumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if targetHumanoidRootPart and myHumanoidRootPart then
        -- Calcular a direção oposta ao alvo
        local direction = (myHumanoidRootPart.Position - targetHumanoidRootPart.Position).unit
        local targetPosition = targetHumanoidRootPart.Position + direction * 5 -- 5 studs atrás do alvo

        -- Teleportar para a nova posição usando tgoto
        tgoto(targetPosition)
    end
end

-- Função principal chamada periodicamente
local function onUpdate()
    local currentTime = tick()

    if currentTime - lastUpdate < updateInterval then
        return -- Não atualizar se o intervalo de atualização não foi atingido
    end
    lastUpdate = currentTime

    local closestPlayer = nil
    local minDistance = math.huge

    for _, targetPlayer in pairs(players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            local targetCharacter = targetPlayer.Character
            local targetHumanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
            local myHumanoidRootPart = character:FindFirstChild("HumanoidRootPart")

            if targetHumanoidRootPart and myHumanoidRootPart then
                local distance = (myHumanoidRootPart.Position - targetHumanoidRootPart.Position).magnitude
                if distance < minDistance and targetCharacter:FindFirstChild("Humanoid") and targetCharacter.Humanoid.Health > 0 then
                    -- Verificar se o jogador alvo é da mesma equipe
                    if not sameTeam(player, targetPlayer) then
                        minDistance = distance
                        closestPlayer = targetPlayer
                    end
                end
            end
        end
    end

    if closestPlayer then
        local targetPosition = closestPlayer.Character:FindFirstChild("HumanoidRootPart").Position

        -- Verificar a distância para o teletransporte
        local myHumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local currentDistance = (myHumanoidRootPart.Position - targetPosition).magnitude

        if currentDistance < maxTeleportDistance then
            if currentTime - lastTeleportTime >= teleportCooldown then
                teleportToBehind(closestPlayer)
                lastTeleportTime = currentTime
            end
        else
            followBehind(closestPlayer.Character:FindFirstChild("HumanoidRootPart").Position)
        end
    end
end

-- Conectar a função de atualização ao `Heartbeat`
rs.Heartbeat:Connect(onUpdate)
