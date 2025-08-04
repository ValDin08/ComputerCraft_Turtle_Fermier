--Déclaration des variables
	--Globales
		local WorkingMode		=	""
	--Inventaire
		--Inventaire flottant (S = Start / E = End)
			local SSeeds		=	1	--Début du stock de graines
			local ESeeds		=	6	--Fin du stock de graines
			local SFuel			=	7	--Début du réservoir à carburant
			local EFuel			=	8	--Fin du réservoir à carburant
			local SHarvest		=	9	--Début du stock de récoltee
			local EHarvest		=	16	--Fin du stock de récolte
		--Inventaire fixe
			
		local InventoryNOK		=	0	--Inventaire pas prêt pour démarrage de la turtle
		local InventoryNeeds	=	0	--Type de besoin de l'inventaire lors de la prochaine sortie (3 bits --> 1 = Graines à recharger / 10 = Carburant à recharger / 100 = Récoltes à déposer)
			
	--Mouvements
		local FieldLength		=	27	--Longueur du champ géré
		local FieldWidth		=	18	--Largeur du champ géré
		local TypeOfMvmt		=	0	--Type de mouvement (0 = Stop / 1 = Avance normale / 2 = Virage gauche / 3 = Virage droit / 4 = guidage GPS)
		local BottomBlock		=	0	--Bloc sous la turtle (0 = Vide / 1 = Récolte NOK / 2 = Récolte OK / 3 = Eau / 4 = Limite)
		
		--Coordonnées
			local TurtleGPSPos	=	{0, 0, 0}		--Position GPS actuelle de la turle
			local TurtleStartPos=	{-45, 66, 52}	--Position GPS de démarrage de la turtle
			local TurtleExitPos	=	{0, 0, 0}		--Position GPS d'entrée/sortie de la zone de travail
			local TurtleFacing	=	0				--Orientation de la turtle (1 = Nord / 2 = Sud / 3 = Est / 4 = Ouest)
			local FuelChest		=	{-47, 66, 53}	--Position du coffre de carburant
			local HarvestChest	=	{-47, 66, 50}	--Position du coffre de récoltes
			local SeedsChest	=	{-43, 66, 52}	--Position du coffre des graines
			local xLine			=	{-68, -40}		--Zone de travail x (min, max)
			local zLine			=	{28, 47}		--Zone de travail z (min, max)
			
			--Coins de la ferme (à gauche de la grille se situe le stand de retrait de la turtle)
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

--PHASE DE DEMARRAGE DE LA TURTLE
function TurtleBooting()
	print("Vérification carburant de la turtle...")
	--Rechargement en carburant de la turtle
	if (turtle.getFuelLevel() < 100) then
		Refuel()
	end
	print("Carburant OK.")
	
	--Instructions de démarrage
	print("Charger la turtle : 1 à 6 = max graines, 7 et 8 = max carburant.")
	print("Vérification du matériel nécessaire en cours.")
	os.sleep(5)

	--Vérification inventaire
	if (turtle.getItemCount(SSeeds) < 5) then
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
	WorkingMode = read()

	if WorkingMode == "auto" then
		--Acquisition de la position de départ
		GetGPSCurrentLoc()
		print("Calibrage position en cours...")
		--Acquisition de l'orientation initiale de la turtle
		TurtleStartPos = TurtleGPSPos
		turtle.forward()
		GetGPSCurrentLoc()
		if     (TurtleGPSPos[3]) < (TurtleStartPos[3]) then TurtleFacing = 1
		elseif (TurtleGPSPos[3]) > (TurtleStartPos[3]) then TurtleFacing = 2
		elseif (TurtleGPSPos[1]) > (TurtleStartPos[1]) then TurtleFacing = 3
		elseif (TurtleGPSPos[1]) < (TurtleStartPos[1]) then TurtleFacing = 4
		end
		turtle.back()
		turtle.turnLeft()
		turtle.turnRight()
		turtle.turnRight()
		turtle.turnLeft()
		turtle.up()
		turtle.down()
	elseif WorkingMode == "manu" then
		print("Entrez point de départ x.")
		TurtleStartPos[1] = read()
		print("Entrez point de départ y.")
		TurtleStartPos[2] = read()
		print("Entrez point de départ z.")
		TurtleStartPos[3] = read()
		print("Entrez orientation de départ : 1 = Nord, 2 = Sud, 3 = Est, 4 = Ouest.")
		TurtleFacing = read()
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
		ManualCoordinates[1] = read()
		print("Entrez coordonnée y cible.")
		ManualCoordinates[2] = read()
		print("Entrez coordonnée z cible. - INACTIF EN v2.0")
		ManualCoordinates[3] = read()
		
		GetGPSCurrentLoc()
		while not TurtleGPSPos[2] == ManualCoordinates[2] do
			if TurtleGPSPos < ManualCoordinates[2] then MoveUp() else MoveDown() end
		end
		
		print("Placement manuel autre que 'y' inactif en v2.0, patientez...")
		os.sleep(2)
		
	elseif WorkingMode == "hold" then 
		os.sleep(2) 
	end
		
end

--SORTIE DE LA TURTLE
function ExitWorkZone()
	--Acquisition position GPS
	GetGPSCurrentLoc()
	--Analyse de l'altitude
	if TurtleGPSPos[2] > (TurtleStartPos[2]+1) then
		while not TurtleGPSPos == (TurtleStartPos[2]+1) do MoveDown() end
	elseif TurtleGPSPos[2] < (TurtleStartPos[2]+1) then
		while not TurtleGPSPos == (TurtleStartPos[2]+1) do MoveUp() end
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
	if TurtleGPSPos[1] < TurtleExitPos[1] then
		TurnRight()
		MoveForward(math.abs(TurtleGPSPos[1]-TurtleExitPos[1]))
		TurnLeft()
		MoveDown()
	elseif TurtleGPSPos[1] > TurtleExitPos[1] then
		TurnLeft()
		MoveForward(math.abs(TurtleGPSPos[1]-TurtleExitPos[1]))
		TurnRight()
		MoveDown()
	end
	
	--Si la turtle est au point de sortie, alors sortie autorisée
	GetGPSCurrentLoc()
	--Actions en dehors de la zone 
	if InventoryNeeds > 0 then
		--Vérification besoin de dépose des récoltes
		if InventoryNeeds >= 100 then
			GetGPSCurrentLoc()
			MoveForward(math.abs(TurtleGPSPos[3]-(HarvestChest[3])))
			TurnRight()
			MoveForward(math.abs(TurtleGPSPos[1]-(HarvestChest[1]+1)))
			for i=SHarvest,EHarvest do
				TransferExtraInventory(i, turtle.getItemCount(i))
			end
			InventoryNeeds = InventoryNeeds - 100
			MoveBackward()
			if not InventoryNeeds == 0 then	TurnLeft() else TurnRight() end
		end
		
		--Vérification besoin rechargement en carburant
		if InventoryNeeds >= 10 then
			GetGPSCurrentLoc()
			MoveForward(math.abs(TurtleGPSPos[3]-(FuelChest[3])))
			TurnRight()
			MoveForward(math.abs(TurtleGPSPos[1]-(FuelChest[1]+1)))
			for i=SFuel,EFuel do
				TransferIntoInventory(i)
			end
			InventoryNeeds = InventoryNeeds - 10
			MoveBackward()
			TurnRight()
		end
		
		--Vérification besoin rechargement en pousses
		if InventoryNeeds == 1 then
			GetGPSCurrentLoc()
			MoveForward(math.abs(TurtleGPSPos[3]-SeedsChest[3]))
			if TurtleFacing == 1 then TurnLeft() elseif TurtleFacing == 2 then TurnRight() end
			MoveForward(math.abs(TurtleGPSPos[1]-(SeedsChest[1]+1)))
			for i=SSeeds,(ESeeds - 1) do
				TransferIntoInventory(i)
			end
			InventoryNeeds = InventoryNeeds - 1
			MoveBackward()
			TurnLeft()
		end
	end
	
	--Retour à la position de travail
	GetInWorkPosition()
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
	elseif (TurtleGPSPos[1] > (SouthEastCorner[1]+1) or TurtleGPSPos[1] < (SouthWestCorner[1]-1)) and TurtleGPSPos[3] = NorthEastCorner[3] then
		TurnRight()	
		MoveForward(math.abs(TurtleGPSPos[3]-SouthEastCorner[3]))
		TurnRight()
	else
		CheckBottomBlock()
		if TypeOfMvmt == 1 then MoveForward(1) end
	end	
end

--RECOLTE ET REPLANTAGE
function Harvest()
	turtle.select(SHarvest)
	--Récupération de la plante
	turtle.digDown()
	--Déplacement du stock turtle
	for i=SHarvest,(EHarvest-1), 1 do
		TransferIntraInventory(i, (i+1), turtle.getItemCount(i))
	end
	--Appel de la fonction de replantage
	Replant()
end

function Replant()
	--Replantage de la pousse
	turtle.select(SSeeds)
	turtle.placeDown()
	for i=ESeeds,(SSeeds+1), 1 do
		TransferIntraInventory(i, (i-1), turtle.getItemCount(i))
	end
end

--RAVITAILLEMENT CARBURANT
function Refuel()
	print("Ravitaillement turtle en cours...")
	turtle.select(SFuel)
	turtle.refuel(turtle.getItemCount(SFuel))
	TransferIntraInventory(EFuel, SFuel, turtle.getItemCount(EFuel))
	os.sleep(1)
end

--GESTION DE L'INVENTAIRE
function TransferIntoInventory(SlotTo)
	turtle.select(SlotTo)
	turtle.suck(64-turtle.getItemCount())
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
	--Vérification besoin de vider la récolte
	if turtle.getItemCount(SHarvest) > 32 then
		InventoryNeeds = InventoryNeeds + 100
	end
	--Vérification besoin de récupérer du carburant
	if turtle.getItemCount(SFuel) < 8 then
		InventoryNeeds = InventoryNeeds + 10
	end
	--Vérification besoin de récupérer des pousses
	if turtle.getItemCount(SSeeds) < 8 then
		InventoryNeeds = InventoryNeeds + 1
	end
	--Vidage de la boite à graines
	if turtle.getItemCount(ESeeds) > 1 then
		turtle.select(ESeeds)
		turtle.drop()
	end
end

--Programme

TurtleBooting()

while true do
	if (turtle.getFuelLevel() < 100) then
		Refuel()
	end
	InventoryCheck()
	if InventoryNeeds == 0 then
		Movement()
	else
		ExitWorkZone()
	end
end
