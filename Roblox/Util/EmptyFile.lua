local CollectionService = game:GetService("CollectionService")
local Signal = loadstring(game:HttpGet('https://raw.githubusercontent.com/skibidiMusic/Lua/refs/heads/main/Roblox/Util/Misc/Signal.lua'))()


local function calculateLandPosition(BallData)
        
end

local TrajectoryCalculator = {}

function TrajectoryCalculator.Join()
        
end

function TrajectoryCalculator.Leave()
        
end

-- Ball Trajectory
do
        local function getCourtPart()
                for _, v in CollectionService:GetTagged("Court") do
                    if v:IsDescendantOf(workspace.Map) then
                        return v
                    end
                end
            end
            
            local BallModule, GameModule
            for _, v in getloadedmodules() do
                if v.Name == "Ball" then
                    BallModule = require(v)
                elseif v.Name == "Game" then
                    GameModule = require(v)
                end
            end
            
            local CourtPart = getCourtPart()
            local newBallSignal, ballDestroySignal, trajectoryUpdatedSignal = Signal.new(), Signal.new(), Signal.new()
            
            local function predictBallLanding(ball)
                local gravityMultiplier = ball.GravityMultiplier or 1
                local acceleration = ball.Acceleration or Vector3.new(0, 0, 0)
                local ballPart = ball.Ball.PrimaryPart
                local velocity, position = ballPart.AssemblyLinearVelocity, ballPart.Position
                local floorY = CourtPart.Position.Y + GameModule.Physics.Radius
                local GRAVITY = GameModule.Physics.Gravity * gravityMultiplier
                
                local a, b, c = 0.5 * (acceleration.Y + GRAVITY), velocity.Y, position.Y - floorY
                local discriminant = b * b - 4 * a * c
                if discriminant < 0 then return nil, nil end
                
                local t1, t2 = (-b + math.sqrt(discriminant)) / (2 * a), (-b - math.sqrt(discriminant)) / (2 * a)
                local timeToHit = (t1 > 0 and t2 > 0) and math.min(t1, t2) or (t1 > 0 and t1) or (t2 > 0 and t2) or nil
                if not timeToHit then return nil, nil end
                
                local landingX = position.X + velocity.X * timeToHit + 0.5 * acceleration.X * timeToHit * timeToHit
                local landingZ = position.Z + velocity.Z * timeToHit + 0.5 * acceleration.Z * timeToHit * timeToHit
                
                trajectoryUpdatedSignal:Fire(ball, Vector3.new(landingX, floorY, landingZ), timeToHit)
            end
            
            local UNHOOKED = false
            
            local oldNew; oldNew = hookfunction(BallModule.new, newcclosure(function(...)
                if UNHOOKED then return oldNew(...) end
                local newBall = oldNew(...)
                newBallSignal:Fire(newBall)
                predictBallLanding(newBall)
                return newBall
            end))
            
            local oldUpdate; oldUpdate = hookfunction(BallModule.Update, newcclosure(function(self, ...)
                if UNHOOKED then return oldUpdate(self, ...) end
                oldUpdate(self, ...)
                predictBallLanding(self)
            end))
            
            local oldDestroy; oldDestroy = hookfunction(BallModule.Destroy, newcclosure(function(self, ...)
                if UNHOOKED then return oldDestroy(self, ...) end
                ballDestroySignal:Fire(self)
                oldDestroy(self, ...)
            end))
            
            local function getAllBalls()
                return BallModule.All
            end
            
            local PreviewConfig = {
                Enabled = false,
                PreviewBallColor = Color3.fromRGB(255, 0, 0),
                PreviewBallTransparency = 0.5,
                BeamColor = Color3.fromRGB(255, 255, 0),
                BeamWidth = 0.2,
            }
            
            local BallPreviews = {}
            local PreviewContainer = Instance.new("Folder")
            PreviewContainer.Name = "BallLandingPreviews"
            PreviewContainer.Parent = workspace
            
            local function removeBallPreview(ball)
                if not BallPreviews[ball] then return end
                for _, obj in pairs(BallPreviews[ball]) do
                    if obj and obj.Parent then obj:Destroy() end
                end
                BallPreviews[ball] = nil
            end
            
            local function createBallPreview(ball)
                if not PreviewConfig.Enabled then return end
                removeBallPreview(ball)
            
                local originalBall = ball.Ball
                local previewBall = originalBall:Clone()
                previewBall.Name = "PreviewBall_" .. originalBall.Name
            
                for _, v in CollectionService:GetTags(previewBall) do
                    CollectionService:RemoveTag(previewBall, v)
                end
            
                for _, part in pairs(previewBall:GetDescendants()) do
                    if part:IsA("BasePart") then
                        for _, v in CollectionService:GetTags(part) do
                            CollectionService:RemoveTag(part, v)
                        end
                        part.Color = PreviewConfig.PreviewBallColor
                        part.Transparency = PreviewConfig.PreviewBallTransparency
                        part.CanCollide, part.Anchored = false, true
                        part.CanQuery, part.CanTouch = false, false
                    end
                end
                previewBall.Parent = PreviewContainer
            
                local sourceAttachment, targetAttachment = Instance.new("Attachment"), Instance.new("Attachment")
                sourceAttachment.Parent, sourceAttachment.Name = originalBall.PrimaryPart, "TrajectoryBeamSource"
                targetAttachment.Parent, targetAttachment.Name = previewBall.PrimaryPart, "TrajectoryBeamTarget"
            
                local beam = Instance.new("Beam")
                beam.Name, beam.Color = "TrajectoryBeam", ColorSequence.new(PreviewConfig.BeamColor)
                beam.Width0, beam.Width1, beam.FaceCamera = PreviewConfig.BeamWidth, PreviewConfig.BeamWidth, true
                beam.Attachment0, beam.Attachment1, beam.Parent = sourceAttachment, targetAttachment, previewBall
            
                BallPreviews[ball] = { PreviewBall = previewBall, Beam = beam, SourceAttachment = sourceAttachment, TargetAttachment = targetAttachment }
            end
            
            local function updateBallPreview(ball, landingPosition)
                if PreviewConfig.Enabled and BallPreviews[ball] then
                    BallPreviews[ball].PreviewBall:SetPrimaryPartCFrame(CFrame.new(landingPosition))
                end
            end
            
            local function cleanupAllPreviews()
                for ball in pairs(BallPreviews) do removeBallPreview(ball) end
                BallPreviews = {}
            end
            
            function ToggleBallTrajectoryPreviews(enabled)
                PreviewConfig.Enabled = enabled
                if not enabled then cleanupAllPreviews() else
                    for _, ball in getAllBalls() do createBallPreview(ball) end
                end
                return PreviewConfig.Enabled
            end
            
            newBallSignal:Connect(createBallPreview)
            trajectoryUpdatedSignal:Connect(function(ball, landingPosition)
                if landingPosition then
                    if BallPreviews[ball] then updateBallPreview(ball, landingPosition) else createBallPreview(ball) end
                else removeBallPreview(ball) end
            end)
            ballDestroySignal:Connect(removeBallPreview)
            
end