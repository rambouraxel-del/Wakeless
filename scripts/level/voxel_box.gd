@tool
class_name VoxelBox
extends Node3D
## Boîte de construction à la main (mur, sol, plafond, meuble massif, ouverture…), à poser dans l'éditeur sous un
## VoxelStructure. Elle ne dessine rien elle-même : la structure rastérise toutes ses boîtes sur la grille de 10 cm,
## dans l'ordre de l'arbre (une boîte « Creuser » retire la matière posée avant elle : portes, fenêtres, niches).
##
## Repère : la position du nœud est le COIN MINIMUM de la boîte (`centered` = faux) ou son centre ; `size` est en
## mètres ; la rotation est ignorée (boîtes alignées sur les axes). Matière = clé de config/palette.json.

enum Mode { AJOUTER, CREUSER }

@export var size := Vector3(1.0, 1.0, 1.0)
@export var material := "plaster_cream"
@export var mode: Mode = Mode.AJOUTER
@export var centered := false

## Cellules [min, max] (bornes incluses) dans le repère de la structure, grille de `cell` mètres.
## La position est cumulée le long de la hiérarchie (les groupes intermédiaires ne doivent être que déplacés).
func cells(structure: Node3D, cell: float) -> Array[Vector3i]:
	var p := position
	var n := get_parent()
	while n != null and n != structure:
		if n is Node3D:
			p += (n as Node3D).position
		n = n.get_parent()
	var lo := p - size * 0.5 if centered else p
	var a := Vector3i((lo / cell).round())
	var b := Vector3i(((lo + size) / cell).round()) - Vector3i.ONE
	b = Vector3i(maxi(a.x, b.x), maxi(a.y, b.y), maxi(a.z, b.z))
	return [a, b]
