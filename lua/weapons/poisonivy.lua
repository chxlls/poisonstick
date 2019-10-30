AddCSLuaFile()
if (SERVER) then
  print("Poison Stick Loaded | Created By Kaden With Help From Azuraii")
end

SWEP.Author                 = "Kaden"
SWEP.Base                   = "weapon_base"
SWEP.PrintName              = "Poison Ivy"
SWEP.Instructions           = [[Left Click: Poison Someone And Steal 5 Health | Right Click: Throw a Poison Ball]]
SWEP.Catergory              = "Kaden's SWEPS"

SWEP.ViewModel              = "models/weapons/c_stunstick.mdl"
SWEP.ViewModelFlip          = false
SWEP.UseHands               = true
SWEP.WorldModel             = "models/weapons/w_stunbaton.mdl"
SWEP.SetHoldType            = "melee"

SWEP.Weight                 = 6
SWEP.AllowsAutoSwitchTo     = true
SWEP.AllowsAutoSwitchFrom   = false

SWEP.Slot                   = 0
SWEP.SlotPos                = 3

SWEP.DrawAmmo               = false
SWEP.DrawCrossHair          = true

SWEP.Spawnable              = true
SWEP.AdminSpawnable         = true

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Ammo           = "none"
SWEP.Primary.Automatic      = false

SWEP.Secondary.Round            = "npc_grenade_bugbait"
SWEP.Secondary.ClipSize       = -1
SWEP.Secondary.DefaultClip    = -1
SWEP.Secondary.Ammo           = "none"
SWEP.Secondary.Automatic      = false

SWEP.ShouldDropOnDie          = true

local SwingSound = Sound( "Weapon_Crowbar.Single" )
local HitSound = Sound( "Weapon_Bugbait.Splat" )
local DeadSound = Sound( "poison/deathsound" )

function SWEP:Initialize()
  self:SetWeaponHoldType( "melee" )
end

function SWEP:PrimaryAttack()

  self.Weapon:SendWeaponAnim( ACT_MELEE_ATTACK1 )
  self.Owner:SetAnimation( PLAYER_ATTACK1 )
  self.Owner:ViewPunch( Angle( 0, math.Rand(-3, -2.8), 0 ) )
  self.Owner:EmitSound( SwingSound )
  self:SetNextPrimaryFire( CurTime() + self:SequenceDuration() + 0.30 )

  if ( CLIENT ) then return end

  local ply = self.Owner
  local tr = ply:GetEyeTrace().Entity

  if( IsValid( tr ) ) then
    ply:LagCompensation( true )
    local tr = ply:GetEyeTrace().Entity
    local ent = tr
    local inrange = ply:GetPos():Distance( ent:GetPos()) <= 150
    if ( IsValid( ent ) && inrange && ( tr:IsPlayer() || ent:IsNPC() ) ) then
      self.Owner:EmitSound( HitSound )
      poisondamage(ply, ent, 10)
    end
    ply:LagCompensation( false )
  end
end

function SWEP:SecondaryAttack()
  local ang = self.Owner:GetAimVector():Angle()
  local vecSrc = self.Owner:GetShootPos() + ang:Forward() * 16 + ang:Right() * 8 - ang:Up() * 8
  if SERVER then
    poisonbugbait = ents.Create("npc_grenade_bugbait")
    poisonbugbait:SetPos(vecSrc)
    poisonbugbait:SetAngles(ang)
    poisonbugbait.ispoison = true
    poisonbugbait:Spawn()
    poisonbugbait:SetOwner(self.Owner)
    poisonbugbait.player = self.Owner
    poisonbugbait:SetLocalVelocity(poisonbugbait:GetVelocity() + self.Owner:GetForward() * 700)
    self:SetNextSecondaryFire( CurTime() + self:SequenceDuration() + 1 )

  end
end

function EntityRemoved(ent)
  if IsValid(ent) and ent:GetClass() == "npc_grenade_bugbait" and ent.ispoison then
    local ply = ent.player
    if CLIENT then return end
    for k, v in pairs( ents.FindInSphere(ent:GetPos(), 15) ) do
      if not v:IsPlayer() then return end
      poisondamage(ply, v, 15, ent)
    end
  end
end

hook.Add("EntityRemoved", "onremovebugbait", EntityRemoved)


function poisondamage(ply, target, damage, ent)
  if CLIENT then return end
  target:SetHealth( math.Clamp( target:Health() - damage, 0, target:GetMaxHealth() )) 
  if ply ~= target then
    ply:SetHealth(  math.Clamp( ply:Health() + damage, 0, ply:GetMaxHealth() ) )
  end
  local notself = ply ~= target and " \nPlayer Poisoned! \nYou Have Stolen " .. damage .. " Health! \nYour Current Health is " .. ply:Health() or " \nYou have poisoned yourself!"
  local poisonmsg =  ply ~= target and " \nYou have been poisoned!\nYou have lost " .. damage .. " health.\nYour current health is " .. target:Health() or  "You have lost " .. damage .. " health\nYour current health is " .. target:Health()
  ply:PrintMessage(HUD_PRINTTALK, notself)
  target:PrintMessage(HUD_PRINTTALK, poisonmsg)
  if( target:Health() <= 0 ) then
    target:TakeDamage( 0, ply, ent)
    target:KillSilent()
  end
  ply:EmitSound( "poison/deathsound" )
end