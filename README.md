# ComputerCraft_Turtle_Fermier
Programme ComputerCraft pour Turtle fermier

Installation du programme : 
  - Dans Minecraft, commencez par placer une turtle dans votre monde, cela va créer un dossier sur votre PC.
  - Dans la turtle, tapez la commande *id*, vous obtiendrez l'ID de votre turtle (numéro unique).
  - Téléchargez le fichier *fermier.lua*, puis copiez le dans : **saves/*MONDE*/computercraft/computer/*id*/** (le dossier *saves* se trouve dans votre dossier d'instance Minecraft/FTB).
  - Dans votre fichier *startup.lua* de ce même dossier, vous pouvez taper *shell.run("fermier")* (peut dépendre de votre version de CC:Tweaked, un simple *fermier()* peut faire l'affaire).
  - Autre solution : copiez le code contenu dans *fermier.lua* dans votre *startup.lua*.
  - Retournez ensuite dans Minecraft, puis, dans votre Turtle, maintenez Ctrl + R jusqu'à ce qu'elle redémarre. Le programme bucheron se lance.

## Exemple de structure d'une ferme à blé : 
<img width="894" height="628" alt="image" src="https://github.com/user-attachments/assets/d676dfe8-5c62-4f88-8f45-2c49cc8444fd" />

---

# Programme : Turtle Fermier
## Version : 1.2

### Patchnote : 

*1.0 : Version de base de la turtle bucheron  
Rechargement et Déchargement automatique de la turtle.  
Positionnement par GPS.  
Mode manuel et automatique.*

*1.1 : Gestion de l'inventaire fluidifiée.*

**1.2 : Casse non prise en compte dans les entrées de strings.  
Affichage de la version du programme au démarrage de la turtle.**

---
> [!NOTE]
> Sortie de la zone de culture pour vidage et remplissage inventaire.

> [!IMPORTANT]
> Dépendante du système GPS. Un GPS doit être ajouté à la Turtle et un satellite doit être mis en place afin de localiser la Turtle.

> [!TIP]
> Le schéma de construction du satellite et ses programmes GPS sont disponibles sur GitHub.

> [!WARNING]
> Pour le bon fonctionnement de votre Turtle, il faut adapter les coordonnées et cotes ci-dessous à votre installation :
> <img width="1301" height="450" alt="image" src="https://github.com/user-attachments/assets/1114cf6f-de60-4482-ac66-545bd546acb9" />


