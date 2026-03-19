# Critique — Kanban Sprints BagTrip (v1)

*Critique du kanban original (10 sprints, 19 semaines) — dans l'esprit de Jonathan Ive*

---

## L'intention est la. L'execution la trahit.

La vision du Sprint 0 est juste : trois piliers — creation unifiee, home contextuelle, mode in-trip. C'est un recit coherent. Le probleme, c'est que la planification qui suit **ne sert pas cette vision**. Elle sert un ingenieur qui pense en couches techniques, pas un designer qui pense en experiences.

---

## 1. La structure est inversee

Les sprints etaient organises ainsi :

```
Sprint 1: Foundation (BLoC, tokens, architecture)
Sprint 2: Home
Sprint 3-4: Creation
Sprint 5: API refactoring
Sprint 6: Detail trip
Sprint 7: Completion
Sprint 8: In-trip mode
Sprint 9: Polish
Sprint 10: Cleanup
```

Le probleme fondamental : **construction de l'interieur vers l'exterieur**. Fondation d'abord, polish a la fin. C'est exactement l'inverse de ce qu'il faut faire.

L'utilisateur ne voit jamais la "foundation". Il voit un ecran. Il le touche. Il ressent quelque chose — ou il ne ressent rien. Si pendant 17 semaines sur 19 l'app n'a ni animations, ni haptics, ni skeleton loading, on ne construit pas un produit. On construit une maquette technique qui deviendra *peut-etre* un produit a la fin.

**Le polish n'est pas une couche qu'on ajoute. C'est la chose elle-meme.**

Quand on dessine une chaise, on ne dessine pas d'abord la structure en acier, puis on ajoute "le confort" au Sprint 9. Le confort *est* la chaise. L'animation de transition entre la home et le detail trip *est* l'experience. Elle doit exister des le Sprint 2, pas au Sprint 9.

---

## 2. Le Sprint 5 est un aveu d'echec architectural

Un sprint entier de refactoring API (Sprint 5) au milieu de la roadmap user-facing. C'est l'equivalent de dire au client : "On arrete de construire votre maison pendant 2 semaines pour refaire la plomberie qu'on aurait du faire correctement au debut."

Ce sprint ne devrait pas exister. Les changements API auraient du etre integres organiquement dans chaque sprint qui en a besoin. Sprint 3 a besoin d'un nouvel endpoint de creation ? On le fait dans Sprint 3. Sprint 6 a besoin d'un endpoint de detail enrichi ? Sprint 6.

Un sprint technique isole est un signal que **l'API et le mobile ne sont pas penses ensemble**. Or dans un produit bien concu, le backend est invisible — il sert l'experience sans qu'on ait besoin de le "refactorer" a mi-chemin.

---

## 3. Le mode In-Trip est le diamant. Il arrive au Sprint 8.

La vision disait :

> *"L'app devient un compagnon actif pendant le voyage — timeline temps reel, actions contextuelles, indicateur 'maintenant'."*

C'est **la** feature qui differencie BagTrip de n'importe quel Google Sheet partage. C'est la raison pour laquelle quelqu'un garderait l'app installee. Et elle etait placee en avant-dernier sprint.

Si cette feature est coupee pour manque de temps (et avec 19 semaines de scope, ce risque est reel), on livre une app de planification de voyage. Il en existe 200. Aucune n'a de mode in-trip avec timeline temps reel.

**Regle : ce qui rend le produit unique doit etre prototype en premier, pas en dernier.**

Au minimum, un prototype fonctionnel du mode in-trip (meme avec des donnees mockees) devrait exister au Sprint 3 ou 4, pour valider que l'idee tient avant d'investir 10 semaines sur le reste.

---

## 4. Les sprints de creation (3-4) sont trop lourds

6 etapes dans un wizard de creation. C'est beaucoup. Chaque etape est un formulaire. Chaque formulaire est une friction.

Le Sprint 0 dit : *"L'IA propose, l'utilisateur valide."* Mais le wizard en 6 etapes est l'exact oppose — c'est l'utilisateur qui remplit, et l'IA qui attend patiemment au Step 3 pour enfin intervenir.

Si l'IA est le coeur du produit, le flow devrait etre :

```
1. "Quand pars-tu ?" → dates
2. "Inspire-moi" → l'IA propose 3 destinations avec tout inclus
3. "Parfait, cree-le" → done
```

3 etapes, pas 6. Le reste (budget, nombre de voyageurs) peut etre capture *apres* la creation, dans le detail du trip. Ou infere par l'IA a partir de l'historique utilisateur.

---

## 5. Incoherences entre les sprints

### a) HomeBloc redesigne deux fois
Sprint 1 refactore HomeBloc avec des states Freezed. Sprint 2 redesigne la Home completement. Sprint 8 re-redesigne la Home pour le mode ActiveTrip. Trois passes sur le meme composant dans trois sprints differents. Chaque passe invalide potentiellement le travail de la precedente.

### b) Tests ecrits a la fin, pas au fil de l'eau
Sprint 9 contient une section massive "Missing tests" avec des tableaux de tests a ecrire pour des features des Sprints 1-8. Si un test n'est pas ecrit avec la feature, il ne sera jamais aussi bon. Le developpeur qui ecrit le test au Sprint 9 n'a plus le contexte mental du Sprint 3.

### c) Les acceptance criteria sont un copier-coller
Presque chaque sprint finit par :
```
- [ ] Dark mode works
- [ ] `flutter analyze` = 0 issues
- [ ] All tests pass
```

Ce n'est pas un acceptance criteria, c'est une checklist CI. Les vrais AC devraient decrire le **comportement utilisateur attendu**, pas l'etat du linter.

---

## 6. 19 semaines — personne n'y croit

10 sprints, ~19 semaines. C'est presque 5 mois. Pour un projet scolaire. Avec :
- Un wizard 6 etapes
- 3 modes de Home
- Un mode in-trip temps reel avec meteo, maps, notifications
- Hero animations, haptics, skeleton loading
- Accessibilite AA
- Golden tests
- CI/CD
- 5 E2E tests complets

C'est le scope d'une equipe de 4-5 developpeurs seniors pendant 5 mois. Pas un junior seul.

**Le risque** : les sprints 8, 9, 10 ne seront jamais atteints. Et ce sont ceux qui contiennent le polish, les tests, le cleanup, et le mode in-trip — autrement dit, tout ce qui fait la difference entre un prototype et un produit.

---

## Ce qui a ete fait (nouveau kanban v2)

La structure a ete replanifiee en **6 sprints** :

```
Sprint 1 (Assainissement) : Fix tous les bugs d'audit + fondation
Sprint 2 (Creation trip)  : Wizard complet avec animations des le jour 1
Sprint 3 (Home + Detail)  : Home contextuelle + trip detail en un seul sprint
Sprint 4 (In-Trip Mode)   : Le differenciateur arrive au Sprint 4, pas au Sprint 8
Sprint 5 (Completion)     : Edition, partage, bagages, budget
Sprint 6 (Tests + Cleanup): Tests manquants, cleanup legacy, CI/CD
```

Les principes :
1. **Chaque sprint livre une experience utilisable**, pas une couche technique
2. **Le polish est inclus dans chaque sprint**, pas repousse
3. **Le mode in-trip arrive au Sprint 4**, pas au Sprint 8
4. **Les tests s'ecrivent avec le code**, pas 6 sprints plus tard
5. **L'API s'adapte au besoin du sprint**, pas dans un sprint dedie

---

## Verdict

La vision est bonne. La planification etait celle d'un ingenieur consciencieux qui veut tout faire bien. Mais "tout faire bien" n'est pas une strategie — c'est un voeu pieux.

Le plus grand risque de ce kanban n'etait pas un bug ou un crash. C'est que dans 4 mois, on ait une app techniquement propre qui ne *ressent* rien. Pas de moment de plaisir. Pas de surprise. Pas de "wow". Parce que ces moments etaient planifies pour les deux dernieres semaines, et les deux dernieres semaines n'arrivent jamais.

**Faire moins. Le faire magnifiquement. Et le faire maintenant, pas au Sprint 9.**
