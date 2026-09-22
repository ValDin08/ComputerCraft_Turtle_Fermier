<p align="center">
<img width="695" height="709" alt="turtle fermier" src="https://github.com/user-attachments/assets/92dfa3ae-da6e-482a-99ef-dd3cbb4d2ace" />
</p>

# ComputerCraft Turtle Fermier
Programme ComputerCraft pour Turtle fermier

Installation du programme : 
  - Dans Minecraft, commencez par placer une turtle dans votre monde, cela va créer un dossier sur votre PC.
  - Dans la turtle, tapez la commande *id*, vous obtiendrez l'ID de votre turtle (numéro unique).
  - Téléchargez le fichier *fermier.lua*, puis copiez le dans : **saves/*MONDE*/computercraft/computer/*id*/** (le dossier *saves* se trouve dans votre dossier d'instance Minecraft/FTB).
  - Téléchargez également *PixelLink.lua* (disponible sur le dépôt [ComputerCraft_Reseau](https://github.com/ValDin08/ComputerCraft_Reseau/tree/main/PixelLink)) et copiez-le dans le même dossier.
  - Dans votre fichier *startup.lua* de ce même dossier, vous pouvez taper *shell.run("fermier")* (peut dépendre de votre version de CC:Tweaked, un simple *fermier()* peut faire l'affaire).
  - Autre solution : copiez le code contenu dans *fermier.lua* dans votre *startup.lua*.
  - Retournez ensuite dans Minecraft, puis, dans votre Turtle, maintenez Ctrl + R jusqu'à ce qu'elle redémarre. Le programme fermier se lance.

## Exemple de structure d'une ferme à blé : 
<img width="894" height="628" alt="image" src="https://github.com/user-attachments/assets/d676dfe8-5c62-4f88-8f45-2c49cc8444fd" />

---

# Programme : Turtle Fermier
## Version : 3.0-alpha01
### Génération : Lumen 🔆
*(tableau complet des générations du projet sur le dépôt [ComputerCraft_Turtle_Bucheron](https://github.com/ValDin08/ComputerCraft_Turtle_Bucheron#-générations))*

### Patchnote : 

<details>
  
<summary>Voir l'historique des versions précédentes</summary>

*1.0 : Version de base de la turtle fermier  
Rechargement et Déchargement automatique de la turtle.  
Positionnement par GPS.  
Mode manuel et automatique.*

*1.1 : Gestion de l'inventaire fluidifiée.*

*1.2 : Casse non prise en compte dans les entrées de strings.  
Affichage de la version du programme au démarrage de la turtle.*

</details>

**3.0-alpha01 : Intégration complète de la communication réseau via PixelLink (la turtle tournait jusque là en totale autonomie, sans aucun serveur).  
Ajout de la connexion au serveur, de la demande d'autorisation de travail et de l'envoi de statut à chaque cycle.  
Ajout du ravitaillement/dépôt en cours de route (carburant, graines, récolte), avec retour exact à la position de reprise du forage.  
Ajout de la prise en charge des commandes forcées depuis l'écran serveur (ravitaillement, vidage, resynchronisation), avec accusé de réception fiable.  
Correction d'un bug critique dans `ExitWorkZone` : une comparaison manquant un index comparait la position GPS entière (une table) à un nombre, ce qui aurait fait planter la turtle dès que son altitude différait de la hauteur de travail.  
Correction du replantage : une graine issue de la récolte n'était jamais utilisée pour replanter à cause d'une mauvaise sélection de slot, la case restait donc vide.  
Correction du mode "manu" (bug de précédence qui empêchait toute correction d'altitude, et comparaison table/nombre similaire au bug ci-dessus).  
Correction de la remontée d'erreurs de ravitaillement, et arrêt réel de la turtle en cas d'échec au démarrage.  
Correction du déclencheur de dépose de la récolte, basé désormais sur le stock total plutôt qu'un seul slot.**

---
> [!NOTE]
> Sortie de la zone de culture pour vidage, ravitaillement et dépôt de la récolte, en cours de forage si besoin.

> [!IMPORTANT]
> Dépendante du système GPS. Un GPS doit être ajouté à la Turtle et un satellite doit être mis en place afin de localiser la Turtle.

> [!IMPORTANT]
> Dépendante du système Serveur et du réseau PixelLink.  
> Un Serveur doit être programmé pour communiquer avec la Turtle.  
> Le module PixelLink, [disponible sur GitHub](https://github.com/ValDin08/ComputerCraft_Reseau/tree/main/PixelLink), doit être installé sur la Turtle.

> [!TIP]
> Le programme du serveur fermier 3.0-alpha01 est [disponible sur GitHub](https://github.com/ValDin08/ComputerCraft_Reseau/tree/main/Serveur%20Fermier).

> [!TIP]
> Le schéma de construction du satellite et ses programmes GPS sont [disponibles sur GitHub](https://github.com/ValDin08/ComputerCraft_Satellite_GPS).

> [!WARNING]
> Pour le bon fonctionnement de votre Turtle, il faut adapter les coordonnées et cotes ci-dessous à votre installation :
> <img width="1301" height="450" alt="image" src="https://github.com/user-attachments/assets/1114cf6f-de60-4482-ac66-545bd546acb9" />

> [!WARNING]
> Pour le bon fonctionnement de votre Turtle, il faut adapter l'ID du serveur et le côté où se situe votre Modem.
