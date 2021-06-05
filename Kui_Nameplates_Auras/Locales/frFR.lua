local L = LibStub("AceLocale-3.0"):NewLocale("KuiNameplatesAuras", "frFR", false)
if not L then return end

L["Show my auras"] = "Afficher mes auras"
L["Display auras cast by you on the current target's nameplate"] = "Affiche vos auras sur la barre d'info de votre cible actuelle."
L["Show on trivial units"] = "Afficher sur les unités triviales"
L["Show auras on trivial (half-size, lower maximum health) nameplates."] = "Affiche les auras sur les unités triviales (demi-taille, santé inférieure)."
L["Behaviour"] = "Comportement"
L["Use whitelist"] = "Utiliser la liste blanche"
L["Only display spells which your class needs to keep track of for PVP or an effective DPS rotation. Most passive effects are excluded."] = "Affiche uniquement les sorts dont votre classe a besoin pour le PVP ou pour une rotation efficace. La plupart des effets passifs sont exclus."
L["Show on secondary targets"] = "Afficher sur les cibles secondaires"
L["Attempt to show and refresh auras on secondary targets - i.e. nameplates which do not have a visible unit frame on the default UI. Particularly useful when tanking."] = "Essaie d'afficher et rafraîchir les auras sur les cible secondaires - c-a-d les barre d'info qui n'ont pas d'unité visible. Particulièrement utile si vous êtes tank."
L["Display"] = "Affichage"
L["Pulsate auras"] = "Pulser les auras"
L["Pulsate aura icons when they have less than 5 seconds remaining.\nSlightly increases memory usage."] = "Fait pulser les icônes lorsqu'il leur reste moins de 5 sec.\nAugmente légèrement l'utilisation de la mémoire."
L["Show decimal places"] = "Afficher les décimales"
L["Show decimal places (.9 to .0) when an aura has less than one second remaining, rather than just showing 0."] = "Affichez les décimales (0,9 à 0,0) lorsqu'il reste moins d'une seconde à une aura, plutôt que de simplement afficher 0."
L["Sort auras by time remaining"] = "Trier les auras par temps restant"
L["Increases memory usage."] = "Augmente l'utilisation de la mémoire."
L["Timer threshold (s)"] = "Seuil de temps restant"
L["Timer text will be displayed on auras when their remaining length is less than or equal to this value. -1 to always display timer."] = "Le texte du temps restant sera affiché sur les auras lorsqu'il leur reste une valeur inférieure ou égale à cette valeur. -1 pour toujours afficher."
L["Effect length minimum (s)"] = "Durée d'effet minimum (s)"
L["Auras with a total duration of less than this value will never be displayed. 0 to disable."] = "Les auras dont la durée totale est inférieure à cette valeur ne seront jamais affichées. 0 pour désactiver."
L["Effect length maximum (s)"] = "Durée d'effet maximum (s)"
L["Auras with a total duration greater than this value will never be displayed. -1 to disable."] = "Les auras dont la durée totale est supérieure à cette valeur ne seront jamais affichées. -1 pour désactiver."
L["Size"] = "Taille"
L["Aura icon size on normal frames"] = "Taille des icônes sur les barres normales"
L["Size (trivial)"] = "Taille (triviale)"
L["Aura icon size on trivial frames"] = "Taille des icônes sur les barres triviales"
L["Squareness"] = "Carré"
L["Where 1 is completely square and .5 is completely rectangular"] = "Où 1 est complètement carré et .5 est complètement rectangulaire"

L["Edit spell list"] = "Modifier la list des sorts"
L["Kui |cff9966ffSpell List|r"] = "Kui |cff9966ffList des sorts|r"
L["Verbatim"] = "Textuel"
L["ADD_DESC "] = [[
Convertit le nom en l'ID d'un sort sur votre grimoire et l'ajoute à la liste des sorts suivis.
Il s'agit du comportement par défaut lorsque le texte d'entrée est en |cff88ff88vert|r.
]]
L["VERBATIM_DESC"] = [[
Ajoute le sort sans le convertir à son ID. En d'autres termes et suit toute aura qui correspond à ce nom.
Il s'agit du comportement par défaut lorsque le texte d'entrée est en |cffff0088rouge|r.
Maintenez la touche MAJ tout en appuyant sur Entrée pour forcer cette action.
]]

L["HELP_TEXT"] = [[
Entrez le |cffffff00nom|r ou l'|cffffff00ID|r d'un sort puis appuyez sur Entrée pour l'ajouter.
|cffffff00Clic-droit|r sur les sorts pour les retiter ou ignorer.

Les sorts ne seront détectés que par leurs noms s'ils sont connus (c'est-à-dire visibles et actives dans la page de votre spécialisation) Vous pouvez utiliser la commande |cffffff00/kslc dump|r pour trouver les ID de sorts une fois que vous les avez appliqués à votre cible.

Passez la souris sur les boutons "Ajouter" et "Textuel" pour plus de détails sur ce que chacun d'eux fait.
]]