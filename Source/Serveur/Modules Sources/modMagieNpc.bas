Attribute VB_Name = "modMagieNpc"
Option Explicit

'Thanks to jimpy who found that the animation and the sound wasn't effective when a npc was casting a spell

Private Type SubSpellSlot
Power As Single
Slot As Byte
End Type

Private Sub Tri(ByRef Liste() As SubSpellSlot, bASC As Boolean)
    Dim i As Long, j As Long
    Dim temp As SubSpellSlot
    
    If bASC Then    '  croissant
        For i = LBound(Liste) To UBound(Liste) - 1
            For j = i + 1 To UBound(Liste)
                If Liste(i).Power > Liste(j).Power Then
                    temp.Power = Liste(j).Power: temp.Slot = Liste(j).Slot
                    Liste(j).Power = Liste(i).Power: Liste(j).Slot = Liste(i).Slot
                    Liste(i).Power = temp.Power: Liste(i).Slot = temp.Slot
                End If
            Next j
        Next i
    Else            ' d�croissant
        For i = LBound(Liste) To UBound(Liste) - 1
            For j = i + 1 To UBound(Liste)
                If Liste(i).Power < Liste(j).Power Then
                    temp.Power = Liste(j).Power: temp.Slot = Liste(j).Slot
                    Liste(j).Power = Liste(i).Power: Liste(j).Slot = Liste(i).Slot
                    Liste(i).Power = temp.Power: Liste(i).Slot = temp.Slot
                End If
            Next j
        Next i
    End If
End Sub

Function CanNpcAttackPlayerWithSpell(ByVal MapNpcNum As Byte, ByVal Index As Integer, Optional ByRef SpellSlotNum As Byte) As Boolean
Dim MapNum As Integer, NpcNum As Integer, i As Byte, SubHP() As SubSpellSlot, SubMP() As SubSpellSlot, Paraly() As SubSpellSlot, Decon() As SubSpellSlot, SpellNum As Integer, Tick As Long
Dim MPCost As Integer
    
    Tick = GetTickCount
    CanNpcAttackPlayerWithSpell = False
    ReDim SubHP(0): ReDim SubMP(0): ReDim Paraly(0): ReDim Decon(0)
    If Not IsPlaying(Index) Then Exit Function
    
    On Error GoTo er:
    
    ' Check for subscript out of range
    If MapNpcNum <= 0 Or MapNpcNum > MAX_MAP_NPCS Or IsPlaying(Index) = False Then Exit Function
        
    ' Check for subscript out of range
    If MapNpc(GetPlayerMap(Index), MapNpcNum).num <= 0 Or MapNpc(GetPlayerMap(Index), MapNpcNum).num > MAX_NPCS Then Exit Function
        
    MapNum = GetPlayerMap(Index)
    NpcNum = MapNpc(MapNum, MapNpcNum).num
    
    If Not NPCHasSpell(NpcNum) Then Exit Function
    
    ' Make sure the player and npc aren't already dead
    If (Player(Index).Char(Player(Index).CharNum).HP <= 0 Or (MapNpc(MapNum, MapNpcNum).HP <= 0 And CLng(Npc(NpcNum).Inv) = 0)) Then Exit Function
    
    ' Make sure npcs dont attack more then once a second
    If Int(Tick - MapNpc(MapNum, MapNpcNum).SpellTimer) < 1000 Then Exit Function
    
    ' Make sure we dont attack the player if they are switching maps
    If Player(Index).GettingMap = YES Then Exit Function
    
    If IsMissing(SpellSlotNum) Or SpellSlotNum = 0 Then
        For i = 1 To MAX_NPC_SPELLS
        SpellNum = CInt(Npc(NpcNum).Spell(i))
        If SpellNum <= 0 Then GoTo EndSel
        
        ' Make sure we don't divide by zero XD (Thanks to Tony for finding this potential error)
        If Spell(SpellNum).MPCost > 0 Then MPCost = Spell(SpellNum).MPCost Else MPCost = -1
        
        ' Make sure we have enough MagicPoints
        If MapNpc(MapNum, MapNpcNum).MP < MPCost Then GoTo EndSel
        
            Select Case Spell(SpellNum).Type
                Case SPELL_TYPE_SUBHP
                    SubHP(UBound(SubHP)).Power = Spell(SpellNum).Data1 / MPCost
                    SubHP(UBound(SubHP)).Slot = i
                    ReDim Preserve SubHP(0 To UBound(SubHP) + 1) As SubSpellSlot
                Case SPELL_TYPE_SUBMP
                    SubMP(UBound(SubMP)).Power = Spell(SpellNum).Data1 / MPCost
                    SubMP(UBound(SubMP)).Slot = i
                    ReDim Preserve SubMP(0 To UBound(SubMP) + 1) As SubSpellSlot
                Case SPELL_TYPE_PARALY
                    Paraly(UBound(Paraly)).Power = Spell(SpellNum).Data1 / MPCost
                    Paraly(UBound(Paraly)).Slot = i
                    ReDim Preserve Paraly(0 To UBound(Paraly) + 1) As SubSpellSlot
                Case SPELL_TYPE_DECONC
                    Decon(UBound(Decon)).Power = Spell(SpellNum).Data1 / MPCost
                    Decon(UBound(Decon)).Slot = i
                    ReDim Preserve Decon(0 To UBound(Decon) + 1) As SubSpellSlot
            End Select
EndSel:
        Next
        
        DoEvents
        
        If Not Para(Index) Then
            If UBound(Paraly) > 0 Then Call Tri(Paraly, True): SpellSlotNum = Paraly(UBound(Paraly)).Slot: GoTo NBal
            If UBound(Decon) > 0 Then Call Tri(Decon, True): SpellSlotNum = Decon(UBound(Decon)).Slot: GoTo NBal
            If UBound(SubHP) > 0 Then Call Tri(SubHP, True): SpellSlotNum = SubHP(UBound(SubHP)).Slot: GoTo NBal
            If UBound(SubMP) > 0 Then Call Tri(SubMP, True): SpellSlotNum = SubMP(UBound(SubMP)).Slot: GoTo NBal
        ElseIf Point(Index) <= 0 Then
            If UBound(Decon) > 0 Then Call Tri(Decon, True): SpellSlotNum = Decon(UBound(Decon)).Slot: GoTo NBal
            If UBound(SubHP) > 0 Then Call Tri(SubHP, True): SpellSlotNum = SubHP(UBound(SubHP)).Slot: GoTo NBal
            If UBound(SubMP) > 0 Then Call Tri(SubMP, True): SpellSlotNum = SubMP(UBound(SubMP)).Slot: GoTo NBal
        ElseIf GetPlayerMaxHP(Index) > GetPlayerMaxMP(Index) Or GetPlayerMP(Index) / GetPlayerMaxMP(Index) * 100 <= 40 Then
            If UBound(SubHP) > 0 Then Call Tri(SubHP, True): SpellSlotNum = SubHP(UBound(SubHP)).Slot: GoTo NBal
            If UBound(SubMP) > 0 Then Call Tri(SubMP, True): SpellSlotNum = SubMP(UBound(SubMP)).Slot: GoTo NBal
        Else
            If UBound(SubMP) > 0 Then Call Tri(SubMP, True): SpellSlotNum = SubMP(UBound(SubMP)).Slot: GoTo NBal
            If UBound(SubHP) > 0 Then Call Tri(SubHP, True): SpellSlotNum = SubHP(UBound(SubHP)).Slot: GoTo NBal
        End If
        
        If SpellSlotNum <= 0 Then Exit Function
    Else
        SpellNum = Spell(Npc(NpcNum).Spell(SpellSlotNum)).Type
        If SpellNum <> SPELL_TYPE_SUBHP Or SpellNum <> SPELL_TYPE_SUBMP Or SpellNum <> SPELL_TYPE_DECONC Or SpellNum <> SPELL_TYPE_PARALY Then Exit Function
    End If

NBal:
    If SpellSlotNum <= 0 Then Exit Function
    DoEvents
    MapNpc(MapNum, MapNpcNum).AttackTimer = GetTickCount

    ' Check if at same coordinates
    If Abs(Player(Index).Char(Player(Index).CharNum).Y - MapNpc(MapNum, MapNpcNum).Y) <= Spell(Npc(NpcNum).Spell(SpellSlotNum)).Range And Abs(Player(Index).Char(Player(Index).CharNum).X - MapNpc(MapNum, MapNpcNum).X) <= Spell(Npc(NpcNum).Spell(SpellSlotNum)).Range Then
        CanNpcAttackPlayerWithSpell = True
    Else: Exit Function
    End If
Exit Function
er:
CanNpcAttackPlayerWithSpell = False
On Error Resume Next
If Index < 0 Or Index > MAX_PLAYERS Then Exit Function
Call PlayerMsg(Index, "Attaque du PNJ annul�e � cause d'une erreur si le probl�me persiste contactez un administrateur.", Red)
Call AddLog("le : " & Date & "     � : " & Time & "...Erreur dans l'attaque d'un joueur(" & Player(Index).Login & ")par un PNJ(" & NpcNum & ")� l'Aide du sort(" & SpellNum & "). D�tails : Num :" & Err.Number & " Description : " & Err.description & " Source : " & Err.Source & "...", "logs\Err.txt")
If IBErr Then Call IBMsg("Erreur dans l'attaque d'un joueur(" & GetPlayerName(Index) & ")par un PNJ(" & NpcNum & ")� l'Aide du sort(" & SpellNum & ")", BrightRed, True)
End Function

Function CanNpcRestoreHimself(ByVal MapNpcNum As Byte, ByVal MapNum As Integer, Optional ByRef SpellSlotNum As Byte) As Boolean
Dim NpcNum As Integer, i As Byte, ResHP() As SubSpellSlot, ResMP() As SubSpellSlot, Amelio() As SubSpellSlot, Defenc() As SubSpellSlot, SpellNum As Integer, Tick As Long

    Tick = GetTickCount
    CanNpcRestoreHimself = False
    ReDim ResHP(0): ReDim ResMP(0): ReDim Amelio(0): ReDim Defenc(0)
    
    On Error GoTo er:
    ' Check for subscript out of range
    If MapNpcNum <= 0 Or MapNpcNum > MAX_MAP_NPCS Or MapNum <= 0 Or MapNum > MAX_MAPS Then Exit Function
    If MapNpc(MapNum, MapNpcNum).num <= 0 Or MapNpc(MapNum, MapNpcNum).num > MAX_NPCS Then Exit Function
    
    NpcNum = MapNpc(MapNum, MapNpcNum).num
    
    If Not NPCHasSpell(NpcNum) Then Exit Function
    If (MapNpc(MapNum, MapNpcNum).HP <= 0 And CLng(Npc(NpcNum).Inv) = 0) Then Exit Function
    If Int(Tick - MapNpc(MapNum, MapNpcNum).SpellTimer) < 1000 Then Exit Function
    If MapNpc(MapNum, MapNpcNum).HP > Npc(NpcNum).MaxHp * 40 / 100 And MapNpc(MapNum, MapNpcNum).MP > Int(GetNpcMaxMP(NpcNum) + IIf(MapNpc(MapNum, MapNpcNum).Amelio.Timer >= GetTickCount, MapNpc(MapNum, MapNpcNum).Amelio.Power * 2, 0)) * 40 / 100 And MapNpc(MapNum, MapNpcNum).Amelio.Timer < GetTickCount And MapNpc(MapNum, MapNpcNum).Immune < GetTickCount Then Exit Function
    
    If IsMissing(SpellSlotNum) Or SpellSlotNum = 0 Then
        For i = 1 To MAX_NPC_SPELLS
        SpellNum = CInt(Npc(NpcNum).Spell(i))
        If SpellNum <= 0 Then GoTo EndSel
        
        ' Make sure we have enough MagicPoints
        If MapNpc(MapNum, MapNpcNum).MP < Spell(SpellNum).MPCost Then GoTo EndSel
        
            Select Case Spell(SpellNum).Type
                Case SPELL_TYPE_ADDHP
                    ResHP(UBound(ResHP)).Power = Spell(SpellNum).Data1 / Spell(SpellNum).MPCost
                    ResHP(UBound(ResHP)).Slot = i
                    ReDim Preserve ResHP(0 To UBound(ResHP) + 1) As SubSpellSlot
                Case SPELL_TYPE_ADDMP
                    ResMP(UBound(ResMP)).Power = Spell(SpellNum).Data1 / Spell(SpellNum).MPCost
                    ResMP(UBound(ResMP)).Slot = i
                    ReDim Preserve ResMP(0 To UBound(ResMP) + 1) As SubSpellSlot
                Case SPELL_TYPE_AMELIO
                    Amelio(UBound(Amelio)).Power = Spell(SpellNum).Data3 / Spell(SpellNum).MPCost / Spell(SpellNum).Data1
                    Amelio(UBound(Amelio)).Slot = i
                    ReDim Preserve Amelio(0 To UBound(Amelio) + 1) As SubSpellSlot
                Case SPELL_TYPE_DEFENC
                    Defenc(UBound(Defenc)).Power = Spell(SpellNum).Data1 / Spell(SpellNum).MPCost
                    Defenc(UBound(Defenc)).Slot = i
                    ReDim Preserve Defenc(0 To UBound(Defenc) + 1) As SubSpellSlot
            End Select
EndSel:
        Next
        
        DoEvents
        If MapNpc(MapNum, MapNpcNum).Immune < GetTickCount And MapNpc(MapNum, MapNpcNum).HP / Npc(NpcNum).MaxHp * 100 <= 20 Then
            If UBound(Defenc) > 0 Then Call Tri(Defenc, True): SpellSlotNum = Defenc(UBound(Defenc)).Slot: GoTo NBal
            If UBound(Amelio) > 0 Then Call Tri(Amelio, True): SpellSlotNum = Amelio(UBound(Amelio)).Slot: GoTo NBal
            If UBound(ResHP) > 0 Then Call Tri(ResHP, True): SpellSlotNum = ResHP(UBound(ResHP)).Slot: GoTo NBal
            If UBound(ResMP) > 0 Then Call Tri(ResMP, True): SpellSlotNum = ResMP(UBound(ResMP)).Slot: GoTo NBal
        ElseIf MapNpc(MapNum, MapNpcNum).Amelio.Timer < GetTickCount And MapNpc(MapNum, MapNpcNum).Target > 0 Then
            If UBound(Amelio) > 0 Then Call Tri(Amelio, True): SpellSlotNum = Amelio(UBound(Amelio)).Slot: GoTo NBal
            If UBound(ResHP) > 0 Then Call Tri(ResHP, True): SpellSlotNum = ResHP(UBound(ResHP)).Slot: GoTo NBal
            If UBound(ResMP) > 0 Then Call Tri(ResMP, True): SpellSlotNum = ResMP(UBound(ResMP)).Slot: GoTo NBal
        ElseIf MapNpc(MapNum, MapNpcNum).MP / Int(GetNpcMaxMP(NpcNum) + IIf(MapNpc(MapNum, MapNpcNum).Amelio.Timer >= GetTickCount, MapNpc(MapNum, MapNpcNum).Amelio.Power * 2, 0)) * 100 > 40 And MapNpc(MapNum, MapNpcNum).HP < Int(GetNpcMaxHP(NpcNum) + IIf(MapNpc(MapNum, MapNpcNum).Amelio.Timer >= GetTickCount, MapNpc(MapNum, MapNpcNum).Amelio.Power * 2, 0)) Then
            If UBound(ResHP) > 0 Then Call Tri(ResHP, True): SpellSlotNum = ResHP(UBound(ResHP)).Slot: GoTo NBal
            If UBound(ResMP) > 0 Then Call Tri(ResMP, True): SpellSlotNum = ResMP(UBound(ResMP)).Slot: GoTo NBal
        Else
            If UBound(ResMP) > 0 Then Call Tri(ResMP, True): SpellSlotNum = ResMP(UBound(ResMP)).Slot: GoTo NBal
            If UBound(ResHP) > 0 Then Call Tri(ResHP, True): SpellSlotNum = ResHP(UBound(ResHP)).Slot: GoTo NBal
        End If
        
        If SpellSlotNum <= 0 Then Exit Function
    Else
        SpellNum = Spell(Npc(NpcNum).Spell(SpellSlotNum)).Type
        If SpellNum <> SPELL_TYPE_ADDHP Or SpellNum <> SPELL_TYPE_ADDMP Or SpellNum <> SPELL_TYPE_DEFENC Or SpellNum <> SPELL_TYPE_AMELIO Then Exit Function
    End If

NBal:
    DoEvents
    MapNpc(MapNum, MapNpcNum).AttackTimer = GetTickCount
    
    CanNpcRestoreHimself = True
Exit Function
er:
CanNpcRestoreHimself = False
On Error Resume Next
Call AddLog("le : " & Date & "     � : " & Time & "...Erreur dans la restoration d'un PNJ(" & NpcNum & ")� l'Aide du sort du slot(" & SpellSlotNum & "). D�tails : Num :" & Err.Number & " Description : " & Err.description & " Source : " & Err.Source & "...", "logs\Err.txt")
If IBErr Then Call IBMsg("Erreur dans la restoration d'un PNJ(" & NpcNum & ")� l'Aide du sort du slot(" & SpellSlotNum & ")", BrightRed, True)
End Function

Sub CastSpellOn(ByVal Attacker As Integer, ByVal AttackerType As Byte, ByVal Target As Integer, ByVal TargetType As Byte, ByVal MapNum As Integer, ByVal SpellSlot As Byte)
Dim SpellNum As Integer, Damage As Long, Casted As Boolean
If AttackerType = TARGET_TYPE_NPC Then SpellNum = Npc(MapNpc(MapNum, Attacker).num).Spell(SpellSlot) Else: SpellNum = Player(Attacker).Char(Player(Attacker).CharNum).Spell(SpellSlot)

If TargetType = TARGET_TYPE_PLAYER Then
    If AttackerType = TARGET_TYPE_PLAYER Then
        Call CastSpell(Attacker, SpellSlot)
    ElseIf AttackerType = TARGET_TYPE_NPC Then
        If Not NPCHasSpell(MapNpc(MapNum, Attacker).num) Then Exit Sub
        If SpellNum <= 0 Then Exit Sub
        Call CastSpellTo(Target, SpellNum, Attacker)
    End If
ElseIf TargetType = TARGET_TYPE_NPC Then
    If AttackerType = TARGET_TYPE_NPC Then
        If Not NPCHasSpell(MapNpc(MapNum, Attacker).num) Then Exit Sub
        If SpellNum <= 0 Then Exit Sub
        If Attacker = Target Then
            Select Case Spell(SpellNum).Type
            Case SPELL_TYPE_ADDHP
                MapNpc(MapNum, Target).HP = MapNpc(MapNum, Target).HP + Spell(SpellNum).Data1
                If MapNpc(MapNum, Target).HP > Npc(MapNpc(MapNum, Target).num).MaxHp Then MapNpc(MapNum, Target).HP = Npc(MapNpc(MapNum, Target).num).MaxHp
                Casted = True
            Case SPELL_TYPE_ADDMP
                MapNpc(MapNum, Target).MP = MapNpc(MapNum, Target).MP + Spell(SpellNum).Data1
                If MapNpc(MapNum, Target).MP > GetNpcMaxMP(MapNpc(MapNum, Target).num) + IIf(MapNpc(MapNum, Target).Amelio.Timer >= GetTickCount, MapNpc(MapNum, Target).Amelio.Power * 2, 0) Then MapNpc(MapNum, Target).MP = GetNpcMaxMP(MapNpc(MapNum, Target).num) + IIf(MapNpc(MapNum, Target).Amelio.Timer >= GetTickCount, MapNpc(MapNum, Target).Amelio.Power, 0)
                Casted = True
            Case SPELL_TYPE_DEFENC
                MapNpc(MapNum, Target).Immune = GetTickCount + Val(Spell(SpellNum).Data1 * 1000)
                Casted = True
            Case SPELL_TYPE_AMELIO
                MapNpc(MapNum, Target).Amelio.Power = Spell(SpellNum).Data3
                MapNpc(MapNum, Target).Amelio.Timer = GetTickCount + Val(Spell(SpellNum).Data1 * 100)
                Casted = True
            End Select
        Else
            Select Case Spell(SpellNum).Type
            Case SPELL_TYPE_SUBHP
                Damage = Spell(SpellNum).Data1 - GetPlayerProtection(Target)
                If Damage > 0 Then Call NpcAttackPlayer(Attacker, Target, Damage): Call SendHP(Target)
                Casted = True

            Case SPELL_TYPE_SUBMP
                Call SetPlayerMP(Target, GetPlayerMP(Target) - Spell(SpellNum).Data1)
                Call SendMP(Target)
                Casted = True

            Case SPELL_TYPE_PARALY
                Call ContrOnOff(Target)
                Para(Target) = True
                ParaT(Target) = GetTickCount + Val(Spell(SpellNum).Data1 * 1000)
                Casted = True
            
            Case SPELL_TYPE_DECONC
                Player(Target).Char(Player(Target).CharNum).def = Player(Target).Char(Player(Target).CharNum).def - Val(Spell(SpellNum).Data3)
                Player(Target).Char(Player(Target).CharNum).magi = Player(Target).Char(Player(Target).CharNum).magi - Val(Spell(SpellNum).Data3)
                Player(Target).Char(Player(Target).CharNum).STR = Player(Target).Char(Player(Target).CharNum).STR - Val(Spell(SpellNum).Data3)
                Player(Target).Char(Player(Target).CharNum).Speed = Player(Target).Char(Player(Target).CharNum).Speed - Val(Spell(SpellNum).Data3)
                Call SendStats(Target)
                Point(Target) = SpellNum
                PointT(Target) = GetTickCount + Val(Spell(SpellNum).Data1 * 1000)
                Casted = True
            End Select
        End If
        If Casted Then
            MapNpc(MapNum, Attacker).SpellTimer = GetTickCount
            MapNpc(MapNum, Attacker).MP = MapNpc(MapNum, Attacker).MP - Spell(SpellNum).MPCost
            Call SendDataToMap(MapNum, "spellanim" & SEP_CHAR & SpellNum & SEP_CHAR & Spell(SpellNum).SpellAnim & SEP_CHAR & Spell(SpellNum).SpellTime & SEP_CHAR & Spell(SpellNum).SpellDone & SEP_CHAR & Attacker & SEP_CHAR & TargetType & SEP_CHAR & Target & SEP_CHAR & Player(Target).CastedSpell & SEP_CHAR & END_CHAR)
            Call SendDataToMap(MapNum, "sound" & SEP_CHAR & "magic" & SEP_CHAR & Spell(SpellNum).Sound & SEP_CHAR & END_CHAR)
        End If
    ElseIf AttackerType = TARGET_TYPE_PLAYER Then
        Call CastSpell(Attacker, SpellSlot)
    End If
End If
End Sub

Sub CastSpellTo(ByVal Index As Integer, ByVal SpellNum As Integer, ByVal MapNpcNum As Integer)
Dim Damage As Long, Casted As Boolean
If Not IsPlaying(Index) Or SpellNum <= 0 Or SpellNum > MAX_SPELLS Then Exit Sub
Select Case Spell(SpellNum).Type
Case SPELL_TYPE_SUBHP
    Damage = Spell(SpellNum).Data1 - GetPlayerProtection(Index)
    If Damage > 0 Then
        Call NpcAttackPlayer(MapNpcNum, Index, Damage)
        Call SendHP(Index)
        Casted = True
    End If

Case SPELL_TYPE_SUBMP
    Call SetPlayerMP(Index, GetPlayerMP(Index) - Spell(SpellNum).Data1)
    Call SendMP(Index)
    Casted = True

Case SPELL_TYPE_PARALY
    Call ContrOnOff(Index)
    Para(Index) = True
    ParaT(Index) = GetTickCount + Val(Spell(SpellNum).Data1 * 1000)
    Casted = True

Case SPELL_TYPE_DECONC
    Player(Index).Char(Player(Index).CharNum).def = Player(Index).Char(Player(Index).CharNum).def - Val(Spell(SpellNum).Data3)
    Player(Index).Char(Player(Index).CharNum).magi = Player(Index).Char(Player(Index).CharNum).magi - Val(Spell(SpellNum).Data3)
    Player(Index).Char(Player(Index).CharNum).STR = Player(Index).Char(Player(Index).CharNum).STR - Val(Spell(SpellNum).Data3)
    Player(Index).Char(Player(Index).CharNum).Speed = Player(Index).Char(Player(Index).CharNum).Speed - Val(Spell(SpellNum).Data3)
    Call SendStats(Index)
    Point(Index) = SpellNum
    PointT(Index) = GetTickCount + Val(Spell(SpellNum).Data1 * 1000)
    Casted = True
End Select
If Casted Then
    MapNpc(GetPlayerMap(Index), MapNpcNum).SpellTimer = GetTickCount
    MapNpc(GetPlayerMap(Index), MapNpcNum).MP = MapNpc(GetPlayerMap(Index), MapNpcNum).MP - Spell(SpellNum).MPCost
    Call SendDataToMap(GetPlayerMap(Index), "spellanim" & SEP_CHAR & SpellNum & SEP_CHAR & Spell(SpellNum).SpellAnim & SEP_CHAR & Spell(SpellNum).SpellTime & SEP_CHAR & Spell(SpellNum).SpellDone & SEP_CHAR & Index & SEP_CHAR & MapNpc(GetPlayerMap(Index), MapNpcNum).TargetType & SEP_CHAR & MapNpc(GetPlayerMap(Index), MapNpcNum).Target & SEP_CHAR & Player(Index).CastedSpell & SEP_CHAR & END_CHAR) ' Player(Index).TargetType Player(Index).Target
    Call SendDataToMap(GetPlayerMap(Index), "sound" & SEP_CHAR & "magic" & SEP_CHAR & Spell(SpellNum).Sound & SEP_CHAR & END_CHAR)
End If
End Sub

Public Function NPCHasSpell(ByVal NpcNum As Integer) As Boolean
Dim i As Byte
If NpcNum < 0 Or NpcNum > MAX_NPCS Then Exit Function
For i = 1 To MAX_NPC_SPELLS
    If Npc(NpcNum).Spell(i) > 0 Then NPCHasSpell = True: Exit Function
Next
End Function

Function GetNpcMPRegen(ByVal NpcNum As Integer)
Dim i As Long

    'Prevent subscript out of range
    If NpcNum <= 0 Or NpcNum > MAX_NPCS Then GetNpcMPRegen = 0: Exit Function
    
    i = (Npc(NpcNum).def \ 3)
    If i < 1 Then i = 1
    
    GetNpcMPRegen = i
End Function
