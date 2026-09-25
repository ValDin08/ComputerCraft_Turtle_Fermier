--Déclaration des variables
	--Globales
		local WorkingMode		=	""
		local ProgramVersion	=	"3.0-alpha02"
		local TurtleFunction	=	"fermier"
		local HarvestedHays		=	0		--Nombre de récoltes effectuées sur la run en cours
		local ErrorDetected		=	false	--Erreur détectée
		local Error				=	""		--Erreur remontée par la Turtle
		local InCycle			=	false	--Turtle en production

	--Réseau
		local ServerID			=	12					--ID du serveur
		local ModemSide			=	"right"				--Côté du modem sur la turtle (à vérifier selon le câblage réel)
		local ServerConnected	=	false				--Serveur atteignable et connecté à la turtle
		local ServerAuthorized	=	false				--Serveur connecté à la turtle et autorisant le travail
		local CurrentFuelLevel	=	0					--Niveau de carburant actuel
		local PixelLink			=	require("PixelLink")

	--Inventaire
		--Inventaire flottant (S = Start / E = End)
			local SSeeds	=	3	--Début du stock de graines
			local ESeeds	=	6	--Fin du stock de graines
			local SFuel		=	7	--Début du réservoir à carburant
			local EFuel		=	8	--Fin du réservoir à carburant
			local SHarvest	=	9	--Début du stock de récolte
			local EHarvest	=	16	--Fin du stock de récolte
		--Inventaire fixe
			local Harvester	=	1	--Emplacement de la récolte en cours (blé) ; Harvester+1 = graines collectées

		local InventoryNOK	=	0	--Inventaire pas prêt pour démarrage de la turtle
		-- Besoins d'inventaire à la prochaine sortie, recalculés à chaque InventoryCheck()
		local NeedHarvestDrop	=	false	-- Besoin de déposer la récolte
		local NeedFuel			=	false	-- Besoin de récupérer du carburant
		local NeedSeeds			=	false	-- Besoin de récupérer des graines
		-- Besoins forcés par le serveur (commande tactile), appliqués à la prochaine sortie puis effacés
		local ForcedNeedHarvestDrop	=	false
		local ForcedNeedFuel			=	false
		local LastAppliedCommandID		=	nil	-- Dernière commande serveur appliquée (évite de la réappliquer en boucle)

	--Mouvements
		local FieldLength	=	27	--Longueur du champ géré
		local FieldWidth	=	18	--Largeur du champ géré
		local TypeOfMvmt	=	0	--Type de mouvement (0 = Stop / 1 = Avance normale / 2 = Virage gauche / 3 = Virage droit / 4 = guidage GPS)
		local BottomBlock	=	0	--Bloc sous la turtle (0 = Vide / 1 = Récolte NOK / 2 = Récolte OK / 3 = Eau / 4 = Limite)

		--Coordonnées
			local TurtleGPSPos		=	{0, 0, 0}		--Position GPS actuelle de la turle
			local TurtleStartPos	=	{-45, 66, 52}	--Position GPS de démarrage de la turtle
			local TurtleExitPos		=	{0, 0, 0}		--Position GPS d'entrée/sortie de la zone de travail
			local TurtleFacing		=	0				--Orientation de la turtle (1 = Nord / 2 = Sud / 3 = Est / 4 = Ouest)
			local FuelChest			=	{-47, 66, 53}	--Position du coffre de carburant
			local HarvestChest		=	{-47, 66, 50}	--Position du coffre de récoltes
			local SeedsChest		=	{-43, 66, 52}	--Position du coffre des graines
			local xLine				=	{-68, -40}		--Zone de travail x (min, max)
			local zLine				=	{28, 47}		--Zone de travail z (min, max)

			--Grille des arbres (à gauche de la grille se situe le stand de retrait de la turtle)
			local NorthEastCorner	=	{-41, 65, 29}
			local NorthWestCorner	=	{-67, 65, 29}
			local SouthEastCorner	=	{-41, 65, 46}
			local SouthWestCorner	=	{-67, 65, 46}


--Création des fonctions
--FONCTIONS DEPLACEMENTS DE BASE
function TurnLeft()
	--Virage à gauche et actualisation de la direction de la turtle
	turtle.turnLeft()
	if     TurtleFacing == 1 then TurtleFacing = 4
	elseif TurtleFacing == 2 then TurtleFacing = 3
	elseif TurtleFacing == 3 then TurtleFacing = 1
	else   TurtleFacing = 2
	end
	--Remise à 0 de la commande de mouvement
	TypeOfMvmt = 0
end

function TurnRight()
	--Virage à droite et actualisation de la direction de la turtle
	turtle.turnRight()
	if     TurtleFacing == 1 then TurtleFacing = 3
	elseif TurtleFacing == 2 then TurtleFacing = 4
	elseif TurtleFacing == 3 then TurtleFacing = 2
	else   TurtleFacing = 1
	end
	--Remise à 0 de la commande de mouvement
	TypeOfMvmt = 0
end

function MoveUp()
	turtle.up()
	GetGPSCurrentLoc()
end

function MoveDown()
	turtle.down()
	GetGPSCurrentLoc()
end

function MoveForward(Distance)
	local DistanceDone	=	0
	while DistanceDone < Distance do
		turtle.forward()
		GetGPSCurrentLoc()
		DistanceDone = DistanceDone + 1
	end
	--Remise à 0 de la commande de mouvement
	TypeOfMvmt = 0
	DistanceDone = 0
end

function MoveBackward()
	turtle.back()
	GetGPSCurrentLoc()
end

--ACQUISITION DE LA POSITION GPS ACTUELLE
function GetGPSCurrentLoc()
	TurtleGPSPos = {gps.locate()}
	return TurtleGPSPos
end

--GESTION DU CARBURANT
function FuelManagement()
	CurrentFuelLevel = turtle.getFuelLevel()
	if CurrentFuelLevel < 100 then
		return Refuel()
	end
	return false, ""
end

function Refuel()
	print("Ravitaillement turtle en cours...")
	turtle.select(SFuel)
	local succes = turtle.refuel(turtle.getItemCount(SFuel))
	--Vérification si le ravitaillement s'est correctement passé
	if succes then
		TransferIntraInventory(EFuel, SFuel, turtle.getItemCount(EFuel))
		return false, ""
	else
		return true, "Ravitaillement échoué"
	end
end

--PHASE DE DEMARRAGE DE LA TURTLE
function TurtleBooting()
	print("Vérification carburant de la turtle...")
	--Rechargement en carburant de la turtle
	ErrorDetected, Error = FuelManagement()

	if not ErrorDetected then
		print("Carburant OK.")
	else
		print(Error)
		print("Ravitaillement impossible, le système redémarrera dans 5 secondes.")
		os.sleep(5)
		os.reboot()
	end

	--Instructions de démarrage
	print("Charger la turtle : 3 à 6 = max graines, 7 et 8 = max carburant.")
	print("!!LAISSER LES EMPLACEMENTS 1 ET 2 VIDES!!!")
	print("Vérification du matériel nécessaire en cours.")
	os.sleep(5)

	--Vérification inventaire
	if (turtle.getItemCount(SSeeds) < 5) or (InventoryMonitor(SFuel, EFuel) == 0) then
		print("Chargez la turtle, le système redémarrera dans 5 secondes.")
		os.sleep(5)
		os.reboot()
	else
	--Inventaire OK, préparation turtle
		print("Inventaire OK.")
		os.sleep(1)
		print("Acquisition de la position de départ de la turtle.")
		GetStartLocation()
		print("Démarrage de la turtle dans 10s.")
	end

	os.sleep(10)

	GetInWorkPosition()
	os.sleep(2)
end

function GetStartLocation()
	--Demande de démarrage manuel ou automatique
	print("Fonctionnement 'auto' ou 'manu'?")
	WorkingMode = string.lower(read())

	if WorkingMode == "auto" then
		--Acquisition de la position de départ
		GetGPSCurrentLoc()
		print("Calibrage position en cours...")
		--Acquisition de l'orientation initiale de la turtle
		TurtleStartPos = TurtleGPSPos
		--Déplacement obligatoire pour déduire l'orientation : on dégage l'obstacle éventuel plutôt que de rester bloqué
		while not turtle.forward() do
			print("Calibrage bloqué par un obstacle, dégagement en cours...")
			turtle.dig()
			os.sleep(1)
		end
		GetGPSCurrentLoc()
		if     (TurtleGPSPos[3]) < (TurtleStartPos[3]) then TurtleFacing = 1
		elseif (TurtleGPSPos[3]) > (TurtleStartPos[3]) then TurtleFacing = 2
		elseif (TurtleGPSPos[1]) > (TurtleStartPos[1]) then TurtleFacing = 3
		elseif (TurtleGPSPos[1]) < (TurtleStartPos[1]) then TurtleFacing = 4
		end
		turtle.back()
	elseif WorkingMode == "manu" then
		print("Entrez point de départ x.")
		TurtleStartPos[1] = tonumber(read())
		print("Entrez point de départ y.")
		TurtleStartPos[2] = tonumber(read())
		print("Entrez point de départ z.")
		TurtleStartPos[3] = tonumber(read())
		print("Entrez orientation de départ : 1 = Nord, 2 = Sud, 3 = Est, 4 = Ouest.")
		TurtleFacing = tonumber(read())
	end
	print("Calibrage position terminée.")
	GetGPSCurrentLoc()
	os.sleep(2)

end

function GetInWorkPosition()
	if WorkingMode == "auto" then
		--Comparaison de l'altitude
		GetGPSCurrentLoc()
		--Décollage de la turtle
		if TurtleGPSPos[2] == TurtleStartPos[2] then MoveUp() end

		--Vérification du sens de démarrage de la turtle et déplacement pour rentrer au point le plus proche dans la zone de travail
		if TurtleFacing == 1 then
			MoveForward(math.abs(TurtleGPSPos[3] - zLine[2]))
		elseif TurtleFacing == 2 then
			MoveForward(math.abs(TurtleGPSPos[3] - zLine[1]))
		elseif TurtleFacing == 3 then
			MoveForward(math.abs(TurtleGPSPos[1] - xLine[1]))
		else
			MoveForward(math.abs(TurtleGPSPos[1] - xLine[2]))
		end

		--Mémorisation du point d'entrée/sortie de la zone de travail
		GetGPSCurrentLoc()
		TurtleExitPos = TurtleGPSPos

		--Déplacement vers coin sud est pour démarrage cycle de récolte
		TurnRight()
		MoveForward(math.abs(TurtleGPSPos[1]-SouthEastCorner[1]))
		MoveForward(1)
		TurnLeft()
		MoveForward(math.abs(TurtleGPSPos[3]-SouthEastCorner[3]))
		TurnLeft()

	elseif WorkingMode == "manu" then
		local ManualCoordinates = {0, 0, 0}
		print("Entrez coordonnée x cible. - INACTIF EN v2.0")
		ManualCoordinates[1] = tonumber(read())
		print("Entrez coordonnée y cible.")
		ManualCoordinates[2] = tonumber(read())
		print("Entrez coordonnée z cible. - INACTIF EN v2.0")
		ManualCoordinates[3] = tonumber(read())

		GetGPSCurrentLoc()
		while TurtleGPSPos[2] ~= ManualCoordinates[2] do
			if TurtleGPSPos[2] < ManualCoordinates[2] then MoveUp() else MoveDown() end
		end

		print("Placement manuel autre que 'y' inactif en v2.0, patientez...")
		os.sleep(2)

	elseif WorkingMode == "hold" then
		os.sleep(2)
	end

	InCycle = true

end

--SORTIE DE LA TURTLE
function ExitWorkZone()
	--Acquisition position GPS
	GetGPSCurrentLoc()
	--Analyse de l'altitude
	if TurtleGPSPos[2] > (TurtleStartPos[2]+1) then
		while TurtleGPSPos[2] > (TurtleStartPos[2]+1) do MoveDown() end
	elseif TurtleGPSPos[2] < (TurtleStartPos[2]+1) then
		while TurtleGPSPos[2] < (TurtleStartPos[2]+1) do MoveUp() end
	end

	--Vérification de l'orientation pour définir la rotation de sortie
	if TurtleFacing == 1 then
		TurnLeft()
		TurnLeft()
	elseif TurtleFacing == 4 then
		TurnLeft()
	elseif TurtleFacing == 3 then
		TurnRight()
	end

	--Vérification si pas d'entrave devant la turtle, sinon, avance jusqu'à zLine[2]
	while turtle.detect() do
		TurnRight()
		MoveForward(1)
		TurnLeft()
	end

	--Réacquisition position GPS et déplacement vers zLine[2]
	GetGPSCurrentLoc()
	MoveForward(math.abs(TurtleGPSPos[3]-TurtleExitPos[3]))

	--Vérification position x par rapport au point de sortie
	GetGPSCurrentLoc()
	if TurtleGPSPos[1] > TurtleExitPos[1] then
		TurnRight()
		MoveForward(math.abs(TurtleGPSPos[1]-TurtleExitPos[1]))
		TurnLeft()
		MoveDown()
	elseif TurtleGPSPos[1] < TurtleExitPos[1] then
		TurnLeft()
		MoveForward(math.abs(TurtleGPSPos[1]-TurtleExitPos[1]))
		TurnRight()
		MoveDown()
	end

	--Si la turtle est au point de sortie, alors sortie autorisée
	GetGPSCurrentLoc()
	--Actions en dehors de la zone
	if NeedHarvestDrop or NeedFuel or NeedSeeds then
		--Vérification besoin de dépose des récoltes
		if NeedHarvestDrop then
			GetGPSCurrentLoc()
			MoveForward(math.abs(TurtleGPSPos[3]-(HarvestChest[3])))
			TurnRight()
			MoveForward(math.abs(TurtleGPSPos[1]-(HarvestChest[1]+1)))
			for i=SHarvest,EHarvest do
				TransferExtraInventory(i, turtle.getItemCount(i))
			end
			if InventoryMonitor(SHarvest,EHarvest) > 0 then
				ErrorDetected = true
				Error = "Coffre de récolte plein, dépose incomplète"
				print(Error)
			end
			NeedHarvestDrop = false
			ForcedNeedHarvestDrop = false
			MoveBackward()
			if not (NeedFuel or NeedSeeds) then TurnRight() else TurnLeft() end
		end

		--Vérification besoin rechargement en carburant
		if NeedFuel then
			GetGPSCurrentLoc()
			MoveForward(math.abs(TurtleGPSPos[3]-(FuelChest[3])))
			TurnRight()
			MoveForward(math.abs(TurtleGPSPos[1]-(FuelChest[1]+1)))
			for i=SFuel,EFuel do
				TransferIntoInventory(i)
			end
			if InventoryMonitor(SFuel,EFuel) < 8 then
				ErrorDetected = true
				Error = "Coffre de carburant vide ou insuffisant"
				print(Error)
			end
			NeedFuel = false
			ForcedNeedFuel = false
			MoveBackward()
			TurnRight()
		end

		--Vérification besoin rechargement en graines
		if NeedSeeds then
			GetGPSCurrentLoc()
			MoveForward(math.abs(TurtleGPSPos[3]-SeedsChest[3]))
			if TurtleFacing == 1 then TurnRight() elseif TurtleFacing == 2 then TurnLeft() end
			MoveForward(math.abs(TurtleGPSPos[1]-(SeedsChest[1]+1)))
			for i=SSeeds,(ESeeds - 1) do
				TransferIntoInventory(i)
			end
			if InventoryMonitor(SSeeds,ESeeds - 1) < 8 then
				ErrorDetected = true
				Error = "Coffre de graines vide ou insuffisant"
				print(Error)
			end
			NeedSeeds = false
			MoveBackward()
			TurnLeft()
		end
	elseif not ServerAuthorized then
		MoveForward(math.abs(TurtleGPSPos[3]-TurtleStartPos[3]))
		TurnLeft()
		TurnLeft()
	end

	--Signal hors cycle
	InCycle = false

	--Retour à la position de travail, uniquement si l'autorisation est toujours valide
	while not ServerAuthorized do
		AuthFromServer()
	end

	if ServerAuthorized then GetInWorkPosition() end
end

--ANALYSE DE L'ENVIRONNEMENT
function CheckBottomBlock()
	local BlockBottom, AgeOfPlant = turtle.inspectDown()
	--Vérification s'il y a présence d'un bloc sous la turtle
	if BlockBottom == true then
		--Vérification si le bloc est une plante en pousse ou une plante mature
		if AgeOfPlant.state.age == 7 then Harvest() else TypeOfMvmt = 1 end
	else
	--Passage d'un coup de houe et replantage d'une graine
		turtle.digDown()
		Replant()
		TypeOfMvmt = 1
	end
	--Réacquisition de la position GPS
	GetGPSCurrentLoc()
end

function CheckWorkZoneLimits()
	--Réacquisition de la position GPS
	GetGPSCurrentLoc()
	--Vérification de la zone de travail
	if TurtleFacing == 1 then
		if TurtleGPSPos[3] > zLine[2] then
			MoveBackward()
			TurnLeft()
		end
	elseif TurtleFacing == 2 then
		if TurtleGPSPos[3] < zLine[1] then
			MoveBackward()
			TurnLeft()
		end
	elseif TurtleFacing == 3 then
		if TurtleGPSPos[1] < xLine[1] then
			MoveBackward()
			TurnLeft()
		end
	else
		if TurtleGPSPos[1] > xLine[2] then
			MoveBackward()
			TurnLeft()
		end
	end
end

--DEPLACEMENTS
function Movement()
	GetGPSCurrentLoc()
	--Vérification zone du champ
	if TurtleGPSPos[1] > (SouthEastCorner[1]+1) and TurtleGPSPos[3] > NorthEastCorner[3] then
		TurnLeft()
		MoveForward(1)
		TurnLeft()
		MoveForward(1)
	elseif TurtleGPSPos[1] < (SouthWestCorner[1]-1) and TurtleGPSPos[3] > NorthEastCorner[3] then
		TurnRight()
		MoveForward(1)
		TurnRight()
		MoveForward(1)
	elseif (TurtleGPSPos[1] > (SouthEastCorner[1]+1) or TurtleGPSPos[1] < (SouthWestCorner[1]-1)) and TurtleGPSPos[3] == NorthEastCorner[3] then
		TurnRight()
		MoveForward(math.abs(TurtleGPSPos[3]-SouthEastCorner[3]))
		TurnRight()
		MoveForward(1)
	else
		CheckBottomBlock()
		if TypeOfMvmt == 1 then MoveForward(1) end
	end
end

--RECOLTE ET REPLANTAGE
function Harvest()
	turtle.select(Harvester)
	--Récupération de la plante
	turtle.digDown()
	--Appel de la fonction de replantage
	os.sleep(0.25)
	Replant()
	HarvestedHays = HarvestedHays + 1
end

function Replant()
	--Replantage : utilise en priorité les graines récupérées à la récolte (Harvester+1), sinon la réserve (SSeeds)
	if turtle.getItemCount(Harvester + 1) > 0 then
		turtle.select(Harvester + 1)
	else
		turtle.select(SSeeds)
	end
	turtle.placeDown()
end

--GESTION DE L'INVENTAIRE
function InventoryMonitor(StartSlot, EndSlot)
	local ItemCount = 0
	for i=StartSlot, EndSlot, 1 do
		ItemCount = ItemCount + turtle.getItemCount(i)
	end
	return ItemCount
end

function TransferIntoInventory(SlotTo)
	turtle.select(SlotTo)
	local before = turtle.getItemCount(SlotTo)
	turtle.suck(64-before)
	return turtle.getItemCount(SlotTo) > before
end

function TransferIntraInventory(SlotFrom,SlotTo, Quantity)
	turtle.select(SlotFrom)
	turtle.transferTo(SlotTo , Quantity)
end

function TransferExtraInventory(SlotFrom, Quantity)
	turtle.select(SlotFrom)
	turtle.drop(Quantity)
end

function InventoryCheck()
	-- Seuil de déclenchement du transfert (turtle.transferTo() passe par la même file de commandes
	-- que les actions physiques, donc a un coût réel par appel — pas la peine de trier dès qu'il y a
	-- ne serait-ce qu'un seul item : le blé mûr est dense, ça viderait le slot à quasiment chaque
	-- itération. On attend qu'il soit presque plein, avec largement assez de marge pour ne jamais
	-- déborder entre deux passages (au plus une récolte par itération).
	local TransferThreshold = 48

	--Déplacement des récoltes dans l'inventaire
	if turtle.getItemCount(Harvester) > TransferThreshold then
		for i=EHarvest,SHarvest, -1 do
			if turtle.getItemCount(i) <= (64 - turtle.getItemCount(Harvester)) then
				TransferIntraInventory(Harvester, i, turtle.getItemCount(Harvester))
				break
			end
		end
	end

	--Déplacement des graines dans l'inventaire
	if turtle.getItemCount(Harvester + 1) > TransferThreshold then
		for i=SSeeds,ESeeds, 1 do
			if turtle.getItemCount(i) <= (64 - turtle.getItemCount(Harvester + 1)) then
				TransferIntraInventory(Harvester + 1, i, turtle.getItemCount(Harvester + 1))
				break
			end
		end
	end

	--Recalcul complet des besoins à chaque passage (évite toute dérive si un besoin précédent n'a
	--pas pu être totalement comblé), en tenant compte des demandes forcées par le serveur (IHM tactile)
	local HarvestQty = InventoryMonitor(SHarvest, EHarvest)
	NeedHarvestDrop = (HarvestQty > ((EHarvest - SHarvest + 1) * 32)) or ForcedNeedHarvestDrop
	NeedFuel        = (InventoryMonitor(SFuel, EFuel) < 8) or ForcedNeedFuel
	--Le slot ESeeds sert de trop-plein jeté au sol ci-dessous : on ne le compte pas dans la réserve utile
	NeedSeeds       = InventoryMonitor(SSeeds, ESeeds - 1) < 8

	--Vidage de la boite à graines (trop-plein)
	if turtle.getItemCount(ESeeds) > 1 then
		turtle.select(ESeeds)
		turtle.drop()
	end
end

--PIXELLINK
	--Connexion au serveur
	function ConnectToServer()
		local payload = {}
		ServerConnected = PixelLink.request("connect", "turtle", ServerID, payload)
		if ServerConnected then print("Serveur connecté") else print("Serveur déconnecté") end
	end

	--Envoi du statut de la turtle
	function StatusToServer()
		local SeedsQty = InventoryMonitor(SSeeds,ESeeds)
		local FuelQty = InventoryMonitor(SFuel,EFuel)
		local HarvestQty = InventoryMonitor(SHarvest,EHarvest)
		local payload = {
			turtleType  = TurtleFunction,
			pos         = TurtleGPSPos,
			orientation = TurtleFacing,
			fuel        = turtle.getFuelLevel() + FuelQty,
			running     = InCycle,
			cycles      = HarvestedHays,
			inventory   = {
				rawMaterial       = SeedsQty,
				harvestedMaterial = HarvestQty,
				misc              = 0
				},
			errors        = {Error},
			ackCommandId  = LastAppliedCommandID, -- Accusé de réception de la dernière commande serveur appliquée
			extra         = {}

			}
		PixelLink.send("status", "turtle", ServerID, payload)
	end

	--Demande d'autorisation de travail
	function AuthFromServer()
		local payload = {
			turtleType          = TurtleFunction,
			pos                 = TurtleGPSPos,
			orientation         = TurtleFacing,
			serverAuthorization = ServerAuthorized
		}
		local ok, payload = PixelLink.request("auth", "turtle", ServerID, payload)
		ServerConnected = ok
		if payload and type(payload) == "table" and payload.authorization ~= nil then
			ServerAuthorized = payload.authorization

		else
			ServerAuthorized = false

		end

		--Traitement d'une éventuelle commande forcée par le serveur (boutons tactiles de l'IHM).
		--Le filtrage par ID évite de la réappliquer à chaque interrogation tant que le serveur
		--n'a pas accusé réception via StatusToServer (ackCommandId).
		if payload and type(payload) == "table" and payload.command and payload.command.id ~= LastAppliedCommandID then
			local cmd = payload.command
			if cmd.type == "forceRefuel" then
				ForcedNeedFuel = true
				print("Commande serveur reçue : ravitaillement forcé")

			elseif cmd.type == "forceEmpty" then
				ForcedNeedHarvestDrop = true
				print("Commande serveur reçue : vidage forcé")

			elseif cmd.type == "resync" then
				print("Commande serveur reçue : resynchronisation")
				ConnectToServer()
				StatusToServer()

			end
			LastAppliedCommandID = cmd.id
		end

		if ServerConnected and ServerAuthorized then
			print("Serveur connecté, autorisation de travailler")

		elseif ServerConnected and not ServerAuthorized then
			print("Serveur connecté, interdiction de travailler")

		else
			print("Serveur déconnecté, révocation de l'autorisation de travailler")

		end

	end

--FONCTIONS PARALLELES
	--Programme de récolte
	function Farming()
		while ServerConnected do
			FuelManagement()
			InventoryCheck()
			AuthFromServer()

			if not (NeedHarvestDrop or NeedFuel or NeedSeeds) and ServerAuthorized then
				Movement()
				StatusToServer()

			else
				ExitWorkZone()

			end

			if not ServerAuthorized then
				print("Autorisation refusée, attente 5s avant nouvelle demande.")
				os.sleep(5)
			end

		end

		if not ServerConnected then print("Connexion au serveur perdue, tentative de reconnexion...") end

	end

--Programme
print("Version programme : "..ProgramVersion)
--Ouverture de la connexion au réseau RedNET
if PixelLink then
	rednet.open(ModemSide)

	while true do
		while not ServerConnected do
			ConnectToServer()
			if not ServerConnected then
				print("Serveur inaccessible, nouvelle tentative dans 10s.")
				os.sleep(10)
			end
		end

		print("Serveur connecté, demande d'autorisation de travail...")
		repeat
			AuthFromServer()
			if not ServerAuthorized then
				print("Autorisation refusée, attente 5s avant nouvelle demande.")
				os.sleep(5)
			end
		until ServerAuthorized

		TurtleBooting()
		print("Turtle prête, lancement du programme fermier !")

		Farming()  -- sort si ServerConnected devient false (perte connexion)
	end

else
	print("PixelLink manquant, impossible de démarrer la turtle. Installez le module PixelLink, puis redémarrez la turtle")
	os.sleep()

end
