local RunService = game:GetService("RunService");
local repStorage = game:GetService("ReplicatedStorage");
local UserInputService = game:GetService("UserInputService");
local starterGui = game:GetService("StarterGui");
local players = game:GetService("Players");
local player = players.LocalPlayer;

starterGui:SetCore("TopbarEnabled", false);

--Guns Setup

local g17Model = repStorage:WaitForChild("Glock17Model");
local MP5SDModel = repStorage:WaitForChild("MP5SDModel");
local AK47Model = repStorage:WaitForChild("AK47Model");
local MP7A1Model = repStorage:WaitForChild("MP7A1Model")
local M60Model = repStorage:WaitForChild("M60Model");
local M4Model = repStorage:WaitForChild("M4Model");

local selectedWeapon;

local camera = game:GetService("Workspace").CurrentCamera;
local debris = game:GetService("Debris");
local mouse = player:GetMouse();
local StarterPlayer = game:GetService("StarterPlayer");
local teams = game:GetService("Teams");
local cameraShaker = require(script.CameraShaker);
local leaning = 0;

local playButton = workspace:WaitForChild("PlayButton"):WaitForChild("SurfaceGui"):WaitForChild("Escape");
local skillsButton = workspace:WaitForChild("SkillsButton"):WaitForChild("SurfaceGui"):WaitForChild("Skills");
local backButton = workspace:WaitForChild("BackButton"):WaitForChild("SurfaceGui"):WaitForChild("Back");

--// GUI Referrals \\--

local mainGUI = repStorage:WaitForChild("MainGui");

local function initializeGUI()
	
	local mainGUIClone = mainGUI:Clone();
	mainGUIClone.Parent = player.PlayerGui;
	
	mainFrame = mainGUIClone:WaitForChild("MainFrame");
	crosshair = mainFrame:WaitForChild("Crosshair");
	announcement = mainFrame:WaitForChild("Announcement");
	transition = mainGUIClone:WaitForChild("Transition");
	
	equipment = mainGUIClone:WaitForChild("Equipment");
	weapons = equipment:WaitForChild("Weapons")
	skillTreeButton = equipment:WaitForChild("SkillTree");
	
	skillTreeFrame = mainGUIClone:WaitForChild("SkillTreeFrame");
	skillTreeBackButton = skillTreeFrame:WaitForChild("Return");
	points = skillTreeFrame:WaitForChild("UnspentPoints");
	
	skillTipFrame = mainGUIClone:WaitForChild("SkillTip");
	
	equipment.Visible = false;
	
end

--\\ GUI Referrals //--

--// Audio \\--

local audio = repStorage:WaitForChild("Audio");

local hitFlesh = audio:WaitForChild("hitFlesh2");
local equipSound1 = audio:WaitForChild("equipSound1");
local equipSound2 = audio:WaitForChild("equipSound2");

local glock17ReloadSound = audio:WaitForChild("glockReload");
local MP5SDReloadSound = audio:WaitForChild("MP5SDReload");
local AK47ReloadSound = audio:WaitForChild("AK47Reload");
local M60ReloadSound = audio:WaitForChild("M60Reload");
local M4ReloadSound = audio:WaitForChild("M4Reload");
--local MP7A1ReloadSound = audio:WaitForChild("MP7A1Reload");

local rSounds = repStorage:WaitForChild("ReloadSounds");
local magIn = rSounds:WaitForChild("MagIn");
local magOut = rSounds:WaitForChild("MagOut");

local mouseEnter = audio:WaitForChild("mouseEnter");
local mouseClick = audio:WaitForChild("mouseClick");
local endOfRound = audio:WaitForChild("endOfRound");
local weaponSelect = audio:WaitForChild("weaponSelect");
local buySkill = audio:WaitForChild("buySkill");
local insufficientFunds = audio:WaitForChild("InsufficientFunds");
--local equipSound3 = repStorage:WaitForChild("equipSound3")
--repStorage:WaitForChild("Ambience"):Play();
local wooshSound = audio:WaitForChild("Transition");
local menuMusic = audio:WaitForChild("MenuMusic");
local loaded = audio:WaitForChild("Loaded");
menuMusic:Play();

--\\ Audio //--

-- // Remotes and Functions \\--

local repDamageRemote = repStorage:WaitForChild("ReplicateDamage");
local repCharactersRemote = repStorage:WaitForChild("ReplicateCharacters");
local repShotRemote = repStorage:WaitForChild("ReplicateShooting");
local repEquipRemote = repStorage:WaitForChild("ReplicateEquip");
local repReadiedPlayersRemote = repStorage:WaitForChild("ReplicateReadied");
local repInitializeRemote = repStorage:WaitForChild("ReplicateInitialize");
local repEndMatchRemote = repStorage:WaitForChild("ReplicateEndMatch");
local getDataRemote = repStorage:WaitForChild("GetData");
local incrementDataEvent = repStorage:WaitForChild("IncrementData");

-- \\ Remotes and Functions //--

local hideParticles = {
	NumberSequenceKeypoint.new( 0, 0);    
	NumberSequenceKeypoint.new( 1, 0);   
}

local currentGun;
local thisChar;

--Initialize Camshake
		
local camShake = cameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
	camera.CFrame = camera.CFrame * shakeCFrame;
end)
		
camShake:Start()

local reloading = false;
local equipping = false;

local function equip(weapon)
	
	if currentGun ~= weapon then
		if reloading == true then
			currentGun.reloadAnim:Stop();
			crosshair.Visible = true;
			reloading = false;
		end
		currentGun.shootAnim:Stop();
		equipping = true;
		mouseDown = false;
		local oldGun = currentGun;
		oldGun.clone.Parent = game.Lighting;
		currentGun = weapon;
		currentGun.quickPullAnim:Play(0, 1, 1);
		wait()
		currentGun.clone.Parent = workspace;
		
		repEquipRemote:FireServer(thisChar, oldGun.ThirdPersonClone, currentGun.ThirdPersonClone);
		
		local strippedMuzzle = player.Character:WaitForChild(currentGun.ThirdPersonClone):WaitForChild("FirePart"); --here
			
		strippedMuzzle:WaitForChild("FlashFX3[Burst]").Size = NumberSequence.new(hideParticles);
		strippedMuzzle:WaitForChild("FlashFX3[Front]").Size = NumberSequence.new(hideParticles);
		strippedMuzzle:WaitForChild("FlashFX[Flash]").Size = NumberSequence.new(hideParticles);
		
		local random = math.random(1, 2)
		
		if random == 1 then
			equipSound1:Play()
		elseif random == 2 then
			equipSound2:Play()
		end
		
		currentGun.quickPullAnim.Stopped:Wait()
		equipping = false;
		currentGun.breatheAnim:Play(.2, .5, .5);
	end
end

--Setting up Character

local debounce = 0;
local inQueue = false;

--// Skill Bools \\--
local hasSteadyAim = false;
local hasBetterPlates = false;
local hasQuickFeet = false;

--// Recoil Vars \\--

local hRecoil = 0;
local vRecoil = 0;
local recoilX = 0;
local recoilY = 0;
local recoilAmount = 0;
local deathDebounce = false;

local function initializeGame()
	if debounce == 0 then
		
		menuMusic:Stop();
		loaded:Play();
		
		transition.Visible = true;
		transition.BackgroundTransparency = 0;
		
		debounce = 1;
		inQueue = false;
		transition:WaitForChild("Waiting").Text = "Loading Match... (2/2)";
		
		repCharactersRemote:FireServer(repStorage:WaitForChild(player.Team.Name.."1"), hasBetterPlates)
		
		player.CharacterAdded:Wait();
		
		thisChar = player.Character;
		
		wait(2)
		
		local thisHum = thisChar:WaitForChild("Humanoid"); --problem problem
		
		print(thisHum.Health)
		
		mainFrame.Visible = true;
		mainFrame.Transparency = 1;
		
		--Sounds Setup
		
		local FXFolder = repStorage:WaitForChild("FX");
		local glock17FireSound = FXFolder:WaitForChild("GlockFire");
		--local MP5SDFireSound = FXFolder:WaitForChild("MP5SDFire");
		local casingHit = FXFolder:WaitForChild("casingHit");
		local noBullet = FXFolder:WaitForChild("ranDry");
		
		--Object/Gun Setups
		
		local currentMag = 18;
		
		-- // Setup Glock \\--
				
		local glock = {
			clone = g17Model:Clone();
			head = nil;
			fireRate = 600;
			damage = 30;
			magSize = 18;
			recoil = 3;
			fireType = "Semi-Automatic";
			fireSound = glock17FireSound;
			reloadSound = glock17ReloadSound;
			firePart = nil;
			shootAnim = nil;
			moveAnim = nil;
			breatheAnim = nil;
			quickPullAnim = nil;
			ThirdPersonClone = "Glock17Stripped";
			reloadAnim = nil;
			currentMag = 18;
		}
		
		glock.head = glock.clone:WaitForChild("Head");
		glock.firePart = glock.clone:WaitForChild("FirePart");
		glock.clone.Parent = workspace;
		
		local animsFolder = glock.clone:WaitForChild("Anims");
		glock.shootAnim = glock.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Shoot"));
		glock.shootAnim.Looped = false;
		glock.moveAnim = glock.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Move"));
		glock.breatheAnim = glock.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Breathe"));
		glock.reloadAnim = glock.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Reload"));
		glock.reloadAnim.Looped = false;
		
		glock.quickPullAnim = glock.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("QuickPull"));
		glock.quickPullAnim.Looped = false;
		
		--\\ Setup Glock //--
		
		--// Setup AK47 \\--
		
		local AK47 = {
			clone = AK47Model:Clone();
			head = nil;
			fireRate = 600;--600
			damage = 40;
			magSize = 30;
			recoil = 3.5;
			fireType = "Automatic";
			reloadSound = AK47ReloadSound;
			firePart = nil;
			shootAnim = nil;
			moveAnim = nil;
			breatheAnim = nil;
			reloadAnim = nil;
			quickPullAnim = nil;
			ThirdPersonClone = "AK47Stripped";
			currentMag = 30;
		}
		
		AK47.head = AK47.clone:WaitForChild("Head");
		AK47.firePart = AK47.clone:WaitForChild("FirePart");
		AK47.clone.Parent = workspace;
		
		local animsFolder = AK47.clone:WaitForChild("Anims");
		AK47.shootAnim = AK47.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Shoot"));
		AK47.shootAnim.Looped = false;
		AK47.moveAnim = AK47.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Move"));
		AK47.breatheAnim = AK47.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Breathe"));
		AK47.reloadAnim = AK47.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Reload"));
		AK47.reloadAnim.Looped = false;
		
		AK47.quickPullAnim = AK47.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("QuickPull"));
		AK47.quickPullAnim.Looped = false;
		
		--\\ Setup AK47 //--

		--// Setup MP5SD \\--
		
		local MP5SD = {
			clone = MP5SDModel:Clone();
			head = nil;
			fireRate = 700;
			damage = 25;
			magSize = 30;
			recoil = 2;
			fireType = "Automatic";
			reloadSound = MP5SDReloadSound;
			firePart = nil;
			shootAnim = nil;
			moveAnim = nil;
			breatheAnim = nil;
			reloadAnim = nil;
			quickPullAnim = nil;
			ThirdPersonClone = "MP5SDStripped";
			currentMag = 30;
		}
		
		MP5SD.head = MP5SD.clone:WaitForChild("Head");
		MP5SD.firePart = MP5SD.clone:WaitForChild("FirePart");
		MP5SD.clone.Parent = workspace;
		
		local animsFolder = MP5SD.clone:WaitForChild("Anims");
		MP5SD.shootAnim = MP5SD.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Shoot"));
		MP5SD.shootAnim.Looped = false;
		MP5SD.moveAnim = MP5SD.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Move"));
		MP5SD.breatheAnim = MP5SD.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Breathe"));
		MP5SD.reloadAnim = MP5SD.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Reload"));
		MP5SD.reloadAnim.Looped = false;
		
		MP5SD.quickPullAnim = MP5SD.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("QuickPull"));
		MP5SD.quickPullAnim.Looped = false;
		
		--\\ Setup MP5SD //--
		
		--// Setup MP7A1 \\--
		
		local MP7A1 = {
			clone = MP7A1Model:Clone();
			head = nil;
			fireRate = 950;
			damage = 25;
			magSize = 20;
			recoil = 2.8;
			fireType = "Automatic";
			reloadSound = MP5SDReloadSound;
			firePart = nil;
			shootAnim = nil;
			moveAnim = nil;
			breatheAnim = nil;
			reloadAnim = nil;
			quickPullAnim = nil;
			ThirdPersonClone = "MP7A1Stripped";
			currentMag = 21;
		}
		
		MP7A1.head = MP7A1.clone:WaitForChild("Head");
		MP7A1.firePart = MP7A1.clone:WaitForChild("FirePart");
		MP7A1.clone.Parent = workspace;
		
		local animsFolder = MP7A1.clone:WaitForChild("Anims");
		MP7A1.shootAnim = MP7A1.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Shoot"));
		MP7A1.shootAnim.Looped = false;
		MP7A1.moveAnim = MP7A1.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Move"));
		MP7A1.breatheAnim = MP7A1.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Breathe"));
		MP7A1.reloadAnim = MP7A1.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Reload"));
		MP7A1.reloadAnim.Looped = false;
		
		MP7A1.quickPullAnim = MP7A1.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("QuickPull"));
		MP7A1.quickPullAnim.Looped = false;
		
		--\\ Setup MP7A1 //--
		
		--// Setup M60 \\--
		
		local M60 = {
			clone = M60Model:Clone();
			head = nil;
			fireRate = 700;
			damage = 35;
			magSize = 80;
			recoil = 2;
			fireType = "Automatic";
			reloadSound = M60ReloadSound;
			firePart = nil;
			shootAnim = nil;
			moveAnim = nil;
			breatheAnim = nil;
			reloadAnim = nil;
			quickPullAnim = nil;
			ThirdPersonClone = "M60Stripped";
			currentMag = 81;
		}
		
		M60.head = M60.clone:WaitForChild("Head");
		M60.firePart = M60.clone:WaitForChild("FirePart");
		M60.clone.Parent = workspace;
		
		local animsFolder = M60.clone:WaitForChild("Anims");
		M60.shootAnim = M60.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Shoot"));
		M60.shootAnim.Looped = false;
		M60.moveAnim = M60.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Move"));
		M60.breatheAnim = M60.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Breathe"));
		M60.reloadAnim = M60.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Reload"));
		M60.reloadAnim.Looped = false;
		
		M60.quickPullAnim = M60.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("QuickPull"));
		M60.quickPullAnim.Looped = false;
		
		--\\ Setup M60//--
		
		--// Setup M4 \\--
		
		local M4 = {
			clone = M4Model:Clone();
			head = nil;
			fireRate = 850;
			damage = 33;
			magSize = 30;
			recoil = 2;
			fireType = "Automatic";
			reloadSound = M4ReloadSound;
			firePart = nil;
			shootAnim = nil;
			moveAnim = nil;
			breatheAnim = nil;
			reloadAnim = nil;
			quickPullAnim = nil;
			ThirdPersonClone = "M4Stripped";
			currentMag = 31;
		}
		
		M4.head = M4.clone:WaitForChild("Head");
		M4.firePart = M4.clone:WaitForChild("FirePart");
		M4.clone.Parent = workspace;
		
		local animsFolder = M4.clone:WaitForChild("Anims");
		M4.shootAnim = M4.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Shoot"));
		M4.shootAnim.Looped = false;
		M4.moveAnim = M4.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Move"));
		M4.breatheAnim = M4.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Breathe"));
		M4.reloadAnim = M4.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("Reload"));
		M4.reloadAnim.Looped = false;
		
		M4.quickPullAnim = M4.clone:WaitForChild("AnimCTRL"):LoadAnimation(animsFolder:WaitForChild("QuickPull"));
		M4.quickPullAnim.Looped = false;
		
		--\\ Setup M4 //--
		
		if selectedWeapon == "AK47" then
			primaryWeapon = AK47;
		elseif selectedWeapon == "MP7A1" then
			primaryWeapon = MP7A1;
		elseif selectedWeapon == "M60" then
			primaryWeapon = M60;
		elseif selectedWeapon == "M4" then
			primaryWeapon = M4;
		else
			primaryWeapon = MP5SD;
		end
		secondaryWeapon = glock;
		
		--Animations Setup
		
		local runningDebounce = false;
		local originalHeadCF;
		
		local function update()
			if leaning == 1 then
				thisHum.CameraOffset = thisHum.CameraOffset:lerp(Vector3.new(-1.2, -0.1, 0), .25); -- lean left
				camera.CFrame = camera.CFrame:lerp(currentGun.head.CFrame * CFrame.Angles(0, 0, math.rad(20)), .25);
			elseif leaning == 0 then
				thisHum.CameraOffset = thisHum.CameraOffset:lerp(Vector3.new(0, 0, 0), .25); -- no lean
			elseif leaning == 2 then
				thisHum.CameraOffset = thisHum.CameraOffset:lerp(Vector3.new(1.2, -0.1, 0), .25); -- lean right
				camera.CFrame = camera.CFrame:lerp(currentGun.head.CFrame * CFrame.Angles(0, 0, math.rad(-20)), .25);
			end
			
			if thisChar and thisChar:FindFirstChild("HumanoidRootPart") and thisChar.HumanoidRootPart.Velocity.Magnitude > 0.5 then
				currentGun.moveAnim:AdjustSpeed(thisChar.HumanoidRootPart.Velocity.Magnitude/10);
				if currentGun.moveAnim.IsPlaying == false then
					currentGun.moveAnim:Play(.1, .4, thisChar.HumanoidRootPart.Velocity.Magnitude/10);
				end
			else
				currentGun.moveAnim:Stop(.1);
			end
			
			if recoilX ~= 0 then
        
        		recoilX = recoilX + 2
       			camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(vRecoil * (recoilY/100)), math.rad(hRecoil * (recoilY/100)), 0);
        		recoilY = -recoilX^2 + 100
        		camera.FieldOfView = -1.75 * recoilAmount * math.sin(1/5 * recoilX) + 75

				if recoilX == 0 then
					
					local muzzleFX = currentGun.firePart:GetChildren();
					for i = 1, #muzzleFX do
						muzzleFX[i].Enabled = false;
					end
					
				end
				
   	 		end
			
			currentGun.head.CFrame = camera.CFrame;--:lerp(camera.CFrame, .95);
		end
		
		--End Initialization
		
		local function ejectShell(shell)
			local sClone = shell:Clone();
			sClone.Parent = workspace;
			sClone.Velocity = Vector3.new(sClone.CFrame.LookVector.X * -30, sClone.CFrame.LookVector.Y * 10, sClone.CFrame.LookVector.Z); --experiment more. 150 is way too high, .1 does nothing
			sClone.RotVelocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15));
			--sClone.CanCollide = true;
			debris:AddItem(sClone, 9)
		end
		
		local function recoil(amount)
			camShake:ShakeOnce(amount/5, 3, 0.1, amount/8)
			hRecoil = math.random(-amount, amount)/10;
    		vRecoil = math.random(amount, amount + amount/2)/7;
    		recoilX, recoilY = -10, 0;
    		recoilAmount = amount;
		end
		
		local function raycast(gunModel, damage)
			local ray = Ray.new(camera.CFrame.p, ((camera.CFrame * CFrame.new(0, 0, -50).p) - camera.CFrame.p).unit * 300);
			local hitPart, hitPos, hitNorm = workspace:FindPartOnRay(ray, player.Character, false, true);
			
			--local distance = (glock.firePart.CFrame.p - hitPos).magnitude;
					
			if hitPart then
				local shotDamage = currentGun.damage; --this placed if needed in future
				repDamageRemote:FireServer(hitPart, shotDamage, hitPos, hitNorm, (camera.CFrame * CFrame.new(0, 0, -100).p), currentGun.firePart.Position); --player, part, damage, position, normal, startPos
				if hitPart.Parent and string.find(hitPart.Parent.Name, "Ragdoll") == nil and (string.find(hitPart.Parent.Name, "Spetsnaz") or string.find(hitPart.Parent.Name, "MARSOC")) then
					
					local hitFleshClone = hitFlesh:Clone();
					hitFleshClone.PlaybackSpeed = math.random(90, 110)/100;
					hitFleshClone.Parent = thisChar;
					hitFleshClone:Destroy();
					
					if hitPart.Name == "HeadGear" or hitPart.Name == "Head" then
						local deathEffectClone = audio:WaitForChild("killReward"):Clone();
						deathEffectClone.PlaybackSpeed = math.random(90, 110)/100;
						deathEffectClone.Parent = thisChar;
						deathEffectClone:Play();
						deathEffectClone:Destroy();
					end
				end
			end
			
		end
		
		local lastTick = tick();
		
		local function fireWeapon()
			if (tick() - lastTick) > 60/currentGun.fireRate and currentGun.currentMag > 0 and reloading == false and equipping == false then
					currentGun.currentMag = currentGun.currentMag - 1;
					lastTick = tick();
					repShotRemote:FireServer(thisChar:WaitForChild(currentGun.ThirdPersonClone));
					local muzzleFX = currentGun.firePart:GetChildren();
					for i = 1, #muzzleFX do
						muzzleFX[i].Enabled = true;
					end
					currentGun.shootAnim:Play(.1, .95, 2.25);
					raycast(currentGun.clone, currentGun.damage);
					local cHSoundClone = casingHit:Clone();
					--cHSoundClone.Parent = glock17FireSound.Parent;
					--cHSoundClone.PlaybackSpeed = math.random(90, 100)/100;
					--cHSoundClone:Destroy();
					--ejectShell(currentGun.clone.Shell);
					if hasSteadyAim and thisChar.HumanoidRootPart.Velocity.Magnitude < 1 then
						recoil(currentGun.recoil * .8);
					else
						recoil(currentGun.recoil);		
					end
				else
					if currentGun.currentMag < 1 then
						local eSoundClone = noBullet:Clone();
						eSoundClone.Parent = glock17FireSound.Parent;
						eSoundClone.PlaybackSpeed = math.random(90, 100)/100;
						eSoundClone:Play();
						wait(3)
					end
				end
			wait();
		end
		
		local function shoot() 
			if currentGun.fireType == "Semi-Automatic" then
				
				fireWeapon();
				
			elseif currentGun.fireType == "Automatic" then
				repeat
					
					fireWeapon();
					
					thisHum.WalkSpeed = 7;
					
				until mouseDown == false;
			end
		end
		
		local function keyDown(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
				mouseDown = true
				shoot();
			elseif inputObject.KeyCode == Enum.KeyCode.R and reloading == false then
				local reloadingGun = currentGun;
				reloading = true;
				crosshair.Visible = false;
				currentGun.reloadAnim:Play(.05, .9, 1.2);
				currentGun.reloadSound:Play();
				currentGun.reloadAnim.Stopped:Wait();
				crosshair.Visible = true;
				wait();
				if currentGun  == reloadingGun then
					currentGun.currentMag = currentGun.magSize;
					reloading = false;
				end
			elseif inputObject.KeyCode == Enum.KeyCode.Q then --lean left
				if leaning == 0 then
					leaning = 1;
					return;
				elseif leaning == 1 or leaning == 2 then
					leaning = 0;
					return;
				end
			elseif inputObject.KeyCode == Enum.KeyCode.E then --lean right
				if leaning == 0 then
					leaning = 2;
					return;
				elseif leaning == 2 or leaning == 1 then
					leaning = 0;
					return;
				end
			elseif inputObject.KeyCode == Enum.KeyCode.Two then
				equip(secondaryWeapon);
			elseif inputObject.KeyCode == Enum.KeyCode.One then
				equip(primaryWeapon);
			end
		end
		
		UserInputService.InputEnded:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
				mouseDown = false
			end
		end)
		
		local function healthChange(amount)
			if thisHum.Health <= 0 and deathDebounce == false then
				deathDebounce = true;
				--dieAnim:Play(1);
				connection:Disconnect();
				updateConnection:Disconnect();
				crosshair.Visible = false;
				currentGun.clone:Destroy();
				repDamageRemote:FireServer("reset");
				wait(1)
				deathDebounce = false;
			end
		end
		
		currentGun = primaryWeapon;
		equip(secondaryWeapon); -- place this here because update() references the currentGun
		
		updateConnection = RunService.RenderStepped:Connect(update);
		thisHum.HealthChanged:Connect(healthChange);
		connection = UserInputService.InputBegan:Connect(keyDown);
		
		debounce = 0;
		wait()
		crosshair.Visible = true;
		
		for i = 0, 100, 2 do
			transition.BackgroundTransparency = i/100;
			transition:WaitForChild("Waiting").TextTransparency = i/100;
			transition:WaitForChild("DYK").TextTransparency = i/100;
			wait()
		end
		
		transition.Visible = false;
		
		--// Begin Custom Movement \\--
		
		local MinSpeed = 6;
		local MaxSpeed = 12;
		
		if hasQuickFeet == true then
			MaxSpeed = 13.8;
		end
		
		thisHum.WalkSpeed = MinSpeed
		
		local MoveDirDB = false
	
		local function Accelerate()
			if thisHum.MoveDirection ~= Vector3.new(0, 0, 0) and MoveDirDB == false and thisHum.WalkSpeed < MaxSpeed then
				MoveDirDB = true
				while thisHum.MoveDirection ~= Vector3.new(0, 0, 0) and thisHum.WalkSpeed < MaxSpeed do
					thisHum.WalkSpeed = thisHum.WalkSpeed + 1
					
					RunService.Heartbeat:Wait();
				end
				MoveDirDB = false
			elseif thisHum.MoveDirection == Vector3.new(0, 0, 0) then
				thisHum.WalkSpeed = MinSpeed			
			end
		end
		
		thisHum:GetPropertyChangedSignal("MoveDirection"):Connect(Accelerate)
		
		--// End Custom Movement \\--
	end
end

-- // Begin Menu \\--

local skillsCam = workspace:WaitForChild("CameraPos2");
local mainCam = workspace:WaitForChild("CameraPos");

camera.CameraType = "Scriptable"
	
camera.CFrame = mainCam.CFrame;
	
camShake:ShakeSustain(camShake.Presets.HandheldCamera)

local function onHover()
	mouseEnter:Play();
	playButton.TextTransparency = 0;
end

local function onEndHover()
	playButton.TextTransparency = .4;
end

local function onHoverSkills()
	mouseEnter:Play();
	skillsButton.TextTransparency = 0;
end

local function onEndHoverSkills()
	skillsButton.TextTransparency = .4;
end

local function onHoverBack()
	mouseEnter:Play();
	backButton.TextTransparency = 0;
end

local function onEndHoverBack()
	backButton.TextTransparency = .4;
end

local enteringSkillsScreen = true;

local function onClickSkills()
	mouseClick:Play();
	equipment.Visible = true;
	for i = -0.5, 0, .01 do
		if enteringSkillsScreen == true then
			equipment.Position = UDim2.fromScale(-math.sin(2 * i)^2 - .01, 0);
			camera.CFrame = camera.CFrame:lerp(skillsCam.CFrame, i*2 + 1);
			RunService.Heartbeat:Wait();
		end
	end
end

local function onClickBack()
	mouseClick:Play();
	enteringSkillsScreen = false;
	for i = -1, 0, .02 do
		camera.CFrame = camera.CFrame:lerp(mainCam.CFrame, i + 1);
		equipment.Position = UDim2.fromScale(-i - 1.1, 0);
		RunService.Heartbeat:Wait();
	end
	enteringSkillsScreen = true;
	equipment.Visible = false;
end

local function onClickSkillTree()
	mouseClick:Play();
	skillTreeFrame.Visible = true;
	equipment.Visible = false;
	points.Text = getDataRemote:InvokeServer("UnspentSkillPoints");
end

local function onClickSkillTreeBack()
	mouseClick:Play();
	skillTreeFrame.Visible = false;
	equipment.Visible = true;
end

local function onHoverSkillTreeBack()
	mouseEnter:Play();
	skillTreeBackButton.TextTransparency = 0.5;
end

local function onHoverEndSkillTreeBack()
	skillTreeBackButton.TextTransparency = 0;
end

local function onHoverSkillTree()
	mouseEnter:Play();
	skillTreeButton.TextTransparency = 0;
end

local function onEndHoverSkillTree()
	skillTreeButton.TextTransparency = .4;
end

local oldSelect;
local specifiedWeapon;

local function selectWeapon(weapon) --argument is a weapon frame containing the button, lock, name, tips, etc.
	if weapon:WaitForChild("Lock").Visible == false then
		if oldSelect ~= nil and oldSelect.Name == weapon.Name then
			return;
		end
		if oldSelect then
			oldSelect:WaitForChild("Button").BackgroundTransparency = 1;
			specifiedWeapon.Parent = repStorage;
		end
		
		specifiedWeapon = repStorage:WaitForChild(weapon.Name .. "Display");
		weaponSelect:Play();
		specifiedWeapon.Parent = workspace;
		specifiedWeapon:SetPrimaryPartCFrame(workspace:WaitForChild("WeaponDisplay").CFrame);
		oldSelect = weapon
		oldSelect:WaitForChild("Button").BackgroundTransparency = 0.7;
		
		selectedWeapon = weapon.Name;
	end
end

local function instantiateWeaponButtons()
	local weaponMenuChildren = weapons:GetChildren();
	
	for _, weapon in ipairs(weaponMenuChildren) do
		weapon:WaitForChild("Button").MouseButton1Click:Connect(function()
			selectWeapon(weapon)
		end)
	end
end

local function colorSkillButton(skill)
	--skill.BackgroundColor3 = Color3.new(247, 247, 247);
	skill.BackgroundTransparency = 0;
	skill.BorderColor3 = Color3.new(250, 250, 250)
	skill.BorderSizePixel = 4;
end

local mySkills = {};
local alreadyOwned = false;

local function updateStatsTree(ability)
	
	local skillMenuChildren = skillTreeFrame:GetChildren();
	
	for _, skill in ipairs(skillMenuChildren) do
		
		if skill:FindFirstChild("Name") then
		
			if ability == "startup" then
				
				if getDataRemote:InvokeServer(skill:WaitForChild("Name").Value) == 1 then
					
					for i = 1, #mySkills, 1 do
						if mySkills[i] == skill:WaitForChild("Name").Value then
							print("Already knew about " .. skill:WaitForChild("Name").Value);
							alreadyOwned = true;
						end
					end
					
					if alreadyOwned == false then			
						table.insert(mySkills, skill:WaitForChild("Name").Value);
							
						colorSkillButton(skill)
					end
					
					alreadyOwned = false;
					
					if string.find(skill.Name, 1) ~= nil then
						for _, skillJ in ipairs (skillMenuChildren) do
							if string.find(string.sub(skillJ.Name, 1, string.len(skillJ.Name) - 1), string.sub(skill.Name, 1, string.len(skill.Name) - 1)) ~= nil then
								if string.find(skillJ.Name, 2) ~= nil or string.find(skillJ.Name, 3) ~= nil then
									skillJ:WaitForChild("Lock").Visible = false;
								end
							end
						end
						
					elseif string.find(skill.Name, 2) ~= nil or string.find(skill.Name, 3) ~= nil then
					
						for _, skillJ in ipairs (skillMenuChildren) do
							if string.find(string.sub(skillJ.Name, 1, string.len(skillJ.Name) - 1), string.sub(skill.Name, 1, string.len(skill.Name) - 1)) ~= nil then
								if string.find(skillJ.Name, 4) ~= nil or string.find(skillJ.Name, 5) ~= nil then
									skillJ:WaitForChild("Lock").Visible = false;
								end
							end
						end
					end
				
				end
				
			else --update previously created array with new information
				
				for i = 1, #mySkills, 1 do
					if mySkills[i] == ability:WaitForChild("Name").Value then
						alreadyOwned = true;
					end
				end
				
				if alreadyOwned == false then
				
					table.insert(mySkills, ability:WaitForChild("Name").Value);
				
				end
				
				alreadyOwned = false;
				
				if string.find(ability.Name, 1) ~= nil then
					for _, skillJ in ipairs (skillMenuChildren) do
						if string.find(string.sub(skillJ.Name, 1, string.len(skillJ.Name) - 1), string.sub(ability.Name, 1, string.len(ability.Name) - 1)) ~= nil then
							if string.find(skillJ.Name, 2) ~= nil or string.find(skillJ.Name, 3) ~= nil then
								skillJ:WaitForChild("Lock").Visible = false;
							end
						end
					end
					
				elseif string.find(ability.Name, 2) ~= nil or string.find(ability.Name, 3) ~= nil then
					
					for _, skillJ in ipairs (skillMenuChildren) do
						if string.find(string.sub(skillJ.Name, 1, string.len(skillJ.Name) - 1), string.sub(ability.Name, 1, string.len(ability.Name) - 1)) ~= nil then
							if string.find(skillJ.Name, 4) ~= nil or string.find(skillJ.Name, 5) ~= nil then
								skillJ:WaitForChild("Lock").Visible = false;
							end
						end
					end
				end
				
			end
			
		end
	end
	
	print("your skills are: ")
	for i = 0, #mySkills, 1 do
		print(mySkills[i]);
		if mySkills[i] == "AK47" then
			
			weapons:WaitForChild("AK47"):WaitForChild("Lock").Visible = false;
			
		elseif mySkills[i] == "Steady Aim" then
				
			hasSteadyAim = true;
			
		elseif mySkills[i] == "Quick Feet" then
				
			hasQuickFeet = true;
			
		elseif mySkills[i] == "Better Plates" then
					
			hasBetterPlates = true;
			
		elseif mySkills[i] == "MP7" then
					
			weapons:WaitForChild("MP7A1"):WaitForChild("Lock").Visible = false;	
				
					
		elseif mySkills[i] == "M60" then
					
			weapons:WaitForChild("M60"):WaitForChild("Lock").Visible = false;	
			
		elseif mySkills[i] == "M4" then
					
			weapons:WaitForChild("M4"):WaitForChild("Lock").Visible = false;	
					
		end
	end
	
end

local function selectSkill(skill)
	if getDataRemote:InvokeServer(skill:WaitForChild("Name").Value) == 1 then --get the wanted datastore value with the Name string value indexing a 2D array of all skill datastores
		
		print("Owned: " .. getDataRemote:InvokeServer(skill:WaitForChild("Name").Value))
			
	else
		
	    local unspentSkillPoints = getDataRemote:InvokeServer("UnspentSkillPoints");
		
		
		if skill:FindFirstChild("Lock").Visible == false and unspentSkillPoints >= skill:WaitForChild("Cost").Value then
			buySkill:Play();
			
			colorSkillButton(skill)
			print("purchased "..skill.Name.." for "..skill:WaitForChild("Cost").Value.." skill points")
			incrementDataEvent:FireServer("UnspentSkillPoints", skill:WaitForChild("Cost").Value * -1);
			print(getDataRemote:InvokeServer("UnspentSkillPoints"))
			incrementDataEvent:FireServer(skill:WaitForChild("Name").Value, 1);
			updateStatsTree(skill);
			points.Text = points.Text - 1;
		else
			insufficientFunds:Play();
			print(getDataRemote:InvokeServer(skill:WaitForChild("Name").Value))
		end
	end
	
	return;
end

local function hoverSkill(skill)
	mouseEnter:Play();
	skillTipFrame.Visible = true;
	skillTipFrame:WaitForChild("Name").Text = skill:WaitForChild("Name").Value;
	skillTipFrame:WaitForChild("Tip").Text = skill:WaitForChild("Info").Value;
	skillTipFrame:WaitForChild("Cost").Text = skill:WaitForChild("Cost").Value .. " Skill Points"
	skillTipFrame.Position = UDim2.new(0, mouse.X, 0, mouse.Y - 20);
end

local function hoverEndSkill(skill)
	skillTipFrame.Visible = false;
end

local function instantiateSkillButtons()
	local skillMenuChildren = skillTreeFrame:GetChildren();
	
	for _, skill in ipairs(skillMenuChildren) do
		if string.find(skill.Name, "Skill") ~= nil then
			skill.MouseButton1Click:Connect(function()
				selectSkill(skill);
			end)
			skill.MouseEnter:Connect(function()
				hoverSkill(skill);
			end)
			skill.MouseLeave:Connect(function()
				hoverEndSkill(skill);
			end)
		end
	end
end

local playDebounce = false;

local function onClickPlay()
	if playDebounce == false then
		playDebounce = true;
		mouseClick:Play();
		transition.Visible = true;
		if workspace:WaitForChild("GameActive").Value == true then
			transition:WaitForChild("Waiting").Text = "Waiting For Next Match (spectating coming soon)";
		else
			transition:WaitForChild("Waiting").Text = "Waiting For Players (1/2)";
		end
		for i = 100, 0, -5 do
			transition:WaitForChild("Waiting").TextTransparency = i/100;
			transition.BackgroundTransparency = i/100;
			transition:WaitForChild("LoadingScreen").ImageTransparency = i/100 + .1;
			RunService.Heartbeat:Wait();
		end
		wait(1)
		UserInputService.MouseIconEnabled = false;
		inQueue = true;
		repReadiedPlayersRemote:FireServer(); -- does nothing for 3rd player
		camera.CameraType = "Custom";
		camShake:StopSustained(1);
		while inQueue == true do
			
			local randomTip = math.random(1, 5);
			if randomTip == 1 then
				transition:WaitForChild("DYK").Text = "Did you know? Headshots deal 3x damage!";
			elseif randomTip == 2 then
				transition:WaitForChild("DYK").Text = "Did you know? You can lean with Q/E!";
			elseif randomTip == 3 then
				transition:WaitForChild("DYK").Text = "Did you know? Upper chest shots deal 1.2x damage!";
			elseif randomTip == 4 then
				transition:WaitForChild("DYK").Text = "Did you know? Arm/leg shots deal 0.8x damage!";
			elseif randomTip == 5 then
				transition:WaitForChild("DYK").Text = "Did you know? You can unlock guns & skills via the Tech Tree!";
			end
			
			for i = 100, 0, -2 do
				transition:WaitForChild("DYK").TextTransparency = i/100;
				RunService.Heartbeat:Wait();
			end
			
			wait(4)
			
			for i = 0, 100, 2 do
				transition:WaitForChild("DYK").TextTransparency = i/100;
				RunService.Heartbeat:Wait();
			end
		end
		wait(5)
		playDebounce = false;
	end
end

local function cleanupCharacter()
	
	if primaryWeapon and primaryWeapon.clone then
		primaryWeapon.clone:Destroy();
	end
	if secondaryWeapon and secondaryWeapon.clone then
		secondaryWeapon.clone:Destroy();
	end
	if player.Character then
		player.Character:Destroy();
	end
	if updateConnection ~= nil then
		updateConnection:Disconnect();
	end
	if connection ~= nil then
		connection:Disconnect();
	end
end

local function endMatch(winningTeam, winningCondition)
	
	wait(2)
	
	announcement.Visible = true;
	mainFrame.Visible = true;
	
	endOfRound:Play();
	
	if winningTeam == "Spetsnaz" then
		announcement.Text = "Secured by Spetsnaz"
		mainFrame:WaitForChild("SpetsScore").Text = mainFrame:WaitForChild("SpetsScore").Text + 1;
	elseif winningTeam == "MARSOC" then
		announcement.Text = "Secured by MARSOC"
		mainFrame:WaitForChild("MarsocScore").Text = mainFrame:WaitForChild("MarsocScore").Text + 1;
	end
	
	wooshSound:Play();
	
	for i = 0, 20, .1 do
		mainFrame.Transparency = 1 - i/90;
		announcement.TextTransparency = 1 - i/20;
		RunService.Heartbeat:Wait();
	end
	
	wait(5)
	
	mainFrame.Visible = false;
	announcement.Visible = false;
	cleanupCharacter();
	if tonumber(mainFrame:WaitForChild("MarsocScore").Text) > 4 or tonumber(mainFrame:WaitForChild("SpetsScore").Text) > 4 then
		wait(3);
		camera.CameraType = "Scriptable";
		camera.CFrame = workspace:WaitForChild("CameraPos").CFrame;
		UserInputService.MouseIconEnabled = true;
		mainFrame:WaitForChild("MarsocScore").Text = 0;
		mainFrame:WaitForChild("SpetsScore").Text = 0;
	else
		wait(2);
		repReadiedPlayersRemote:FireServer();		
	end
end

initializeGUI();

transition.Visible = true;
mainFrame.Visible = false;

playButton.MouseButton1Click:Connect(onClickPlay);
playButton.MouseEnter:Connect(onHover);
playButton.MouseLeave:Connect(onEndHover);

skillsButton.MouseButton1Click:Connect(onClickSkills);
skillsButton.MouseEnter:Connect(onHoverSkills);
skillsButton.MouseLeave:Connect(onEndHoverSkills);

backButton.MouseButton1Click:Connect(onClickBack);
backButton.MouseEnter:Connect(onHoverBack);
backButton.MouseLeave:Connect(onEndHoverBack);

skillTreeButton.MouseButton1Click:Connect(onClickSkillTree);

skillTreeBackButton.MouseButton1Click:Connect(onClickSkillTreeBack);
skillTreeBackButton.MouseEnter:Connect(onHoverSkillTreeBack);
skillTreeBackButton.MouseLeave:Connect(onHoverEndSkillTreeBack);

repInitializeRemote.OnClientEvent:Connect(initializeGame);
repEndMatchRemote.OnClientEvent:Connect(endMatch);

instantiateWeaponButtons();
instantiateSkillButtons();
updateStatsTree("startup");
selectWeapon(weapons:WaitForChild("MP5SD"));

local contentProvider = game:GetService("ContentProvider");

transition:WaitForChild("Waiting").Text = "Loading Assets";

repeat
	
	wait();
	
until contentProvider.RequestQueueSize < 5;

for i = 0, 1, .02 do
	
	transition.BackgroundTransparency = i;
	transition:WaitForChild("LoadingScreen").ImageTransparency = i + .1;
	RunService.Heartbeat:Wait();
	
end

transition.Visible = false;

-- \\ Begin Menu //--