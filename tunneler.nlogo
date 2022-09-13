globals [
  tunnel-x
  tunnel-y
  direction
  whats-here
  level
  looper

  temp-weapon

  ;list of spells.  A "0" means the spell is not known.  A "1" means the hero has learned the spell.  A spell costs it's level.  So, a level 1 spell costs 1 mana to cast, etc.
  ;level 1 spells
  spell-magic-missile
  spell-sense-danger
  spell-light

  ;level 2 spells
  spell-flame-tongue
  spell-heal
  spell-smoke-screen

  ;level 3 spells
  spell-enlightenment ;discovers a large swath around hero
  spell-strength ;increased damage
  spell-protection ;increases armor

  ;level 4 spells
  spell-lightning-bolt ;bolt moves from mob to mob inflicting damage
  spell-magic-fire ;every time a mob hits the hero, they also take damage; also produces light similar to "lit" spell
  spell-dexterity ;increased attackroll & armor

  ;level 5 spells
  spell-sanctuary ;mobs unable to hit hero for a short duration.  If hero attacks, the sanctuary goes away
  spell-drain-life ;hp moves from mob to hero
  spell-walk-through-walls ;able to walk through walls for a short duration.  If spells fades while in a wall, the hero dies

  ;level 6 spells
  spell-fireball ;similar to smoke screen, except causes damage
  spell-sleep ;puts all the mobs on the level to sleep for a few ticks
  spell-teleport ;jump to another location

  ;level 7 spells
  spell-sphere-of-annihilation ;creates a globe that moves in a cardinal direction X number of spaces, killing mobs and destroying walls, chests, items, gold and anything else (including ladders!)
  spell-animate-dead ;creates a zombie that follows hero around and attacks mobs
  spell-create-item ;use "drop item" procedure to create a random item

]

breed [buildings building]
breed [heros hero]
breed [citizens citizen]
breed [mobs mob]
breed [treasures treasure]
breed [weapons weapon]
breed [armors armor]
breed [projectiles projectile]
breed [spellbooks spellbook]
breed [torches torch]
breed [treasure-chests treasure-chest]

directed-link-breed [drain-life-vectors drain-life-vector]

treasure-chests-own [
  trapped?
]

torches-own [
  torch-timer ; the duration that the torch can burn
  torch-used
]

spellbooks-own [
  spell-level ;the level of spell that's in the book
]

projectiles-own [
  projectile-damage
  magic-fire
  magic-strength
  magic-protection
  magic-dexterity
]

armors-own [
  armor-name
  armor-value
  armor-cost
  armor-used
]

weapons-own [
  weapon-type ;hand or ranged
  weapon-ammo ;for ranged weapons
  weapon-name
  weapon-damage
  weapon-cost
  weapon-used
]

buildings-own [
  building-type
]

patches-own [
  walkable?
  smoke-screen-timer
  fireball-timer
  discovered?
  trap-door?
  boobytrap?
]

heros-own [
  gold
  xp
  xp-level
  vision
  hp
  max-hp
  mana
  max-mana
  heal-rate
  damage
  magic-light
  magic-strength
  magic-protection
  magic-dexterity
  magic-sense-danger
  magic-sanctuary
  magic-walk-through-walls
  armor-value
  armor-name
  magic-fire
  in-hand
  ranged-weapon
]

mobs-own [
  mob-name
  hp
  max-hp
  heal-rate
  damage
  armor-value
  mob-speed
  sleep-timer ;used by the sleep spell
  mob-color ; used to store color value to return to after sleep spell
  master ; used to determine if the mob is under the control of another (either the hero or another mob)
  magic-fire
  magic-strength
  magic-protection
  magic-dexterity
  magic-walk-thru-walls
  magic-sanctuary
  xp
]

treasures-own [
  coins
]

to cast-sphere-of-annihilation

  ;creates a sphere that destroys everything in it's path

  let sphere-direction user-one-of "Which direction:" [
    "Closest Monster"
    "North"
    "South"
    "East"
    "West"
  ]

  ask one-of heros [
    hatch-projectiles 1 [
      set shape "circle 2"
      set color red
      print (word "A sphere of annihilation forms in front of you.")

      if sphere-direction = "Closest Monster" [
        set heading towards min-one-of mobs [distance myself]
      ]

      if sphere-direction = "North" [set heading 0]
      if sphere-direction = "South" [set heading 180]
      if sphere-direction = "East" [set heading 90]
      if sphere-direction = "West" [set heading 270]

      wait 0.2
    ]
    set mana mana - 7

    ;move projectile and attack roll
    ask one-of projectiles with [shape = "circle 2"] [
      repeat [xp-level + 1] of one-of heros [
        ask other turtles-here with [breed != heros] [die]

        ask patch-here [
          set pcolor black
          set walkable? true
          set smoke-screen-timer 0
          set fireball-timer 0
        ]
        wait 0.3
        if (can-move? 1) and [pycor < 15] of patch-ahead 1 [
          fd 1
          repeat 25 [
            set color random 140
            wait 0.04
          ]
        ]
      ]
      die
    ]
  ]
end

to cast-animate-dead

  ; creates a zombie and assigns it's "master" variable to the hero
  create-mobs 1 [
    set mob-name "zombie"
    set hp 0
    repeat level [set hp hp + random 16 + 1]
    set max-hp hp
    set heal-rate 1
    set armor-value random 35 + 1
    set shape "boss"
    set damage 0
    set damage damage + random 8 + 1
    set mob-speed 1
    set xp ((hp + armor-value) * damage)
    set color 43 ; some kind of ghoulish yellow
    set mob-color color
    set master one-of heros
    setxy [xcor] of one-of heros [ycor] of one-of heros

    if (can-move? 1) and
    (not any? other mobs-on patch-ahead 1) and
    (not any? heros-on patch-ahead 1) and
    ([walkable? = true] of patch-ahead 1 or [magic-walk-thru-walls] of self = 1) and
    ([fireball-timer <= ticks] of patch-ahead 1) and
    [pycor < 15] of patch-ahead 1 [
      fd 1
    ]

  ]

  ask one-of heros [
    set mana mana - 7
  ]


end

to cast-create-item


  ; creates a random item of the highest caliber
  ask heros [
    ask one-of neighbors with [walkable? = true] [drop-item self 99]
    set mana mana - 7
  ]

end

to cast-fireball

  ;creates an area that is on fire for a short period of time.  Any mob in the affected area takes damage so long as the patch is on fire

  let fireball-radius [xp-level] of one-of heros
  if fireball-radius > 5 [set fireball-radius 5] ;cap radius at 5
  ask one-of heros [
    ask patches with [walkable? = true] in-radius fireball-radius [
      set fireball-timer ticks + random ([xp-level] of one-of heros * 10) + 5
    ]
    ask patch-here [set fireball-timer 0]
    ask heros [set mana mana - 6]
  ]

  update-display

end

to cast-sleep

  ;need to add functionality
  ask mobs [
    set sleep-timer (ticks + (random [xp-level] of one-of heros * 4) + [xp-level] of one-of heros)
  ]

end

to cast-teleport

  ;Teleports hero to some random spot on the level

  let valid-landing-spot false
  while [valid-landing-spot = false] [
    ask one-of heros [
      setxy round random-xcor round random-ycor
      if ([walkable? = true] of patch-here or magic-walk-through-walls > 0) and [pycor < 15] of patch-here and not any? other turtles-here [set valid-landing-spot true]
    ]
  ]

end

to cast-walk-through-walls

  ;Enchantment that allows hero walk through walls.  If the enchantment wears off when the hero is in a wall, the hero dies!
  ask one-of heros [
    set magic-walk-through-walls (random (xp-level * 2)) + 10
    set mana mana - 6
    print (word "You feel light and ethereal.")
  ]


end

to cast-drain-life

  ;this spell steals the mobs hp and adds to the hero's total.  If the hero's total exceeds max-hp, then it gradually lowers to the max-hp value
  ask one-of heros [
    hatch-projectiles 1 [
      set shape "drop"
      set color green
      set projectile-damage 0
      set heading towards min-one-of mobs [distance myself]
    ]
    set mana mana - 5

    ;move projectile and attack roll
    ask one-of projectiles with [shape = "drop"] [
      wait 0.4
      set size 2
      repeat [xp-level] of myself [
        wait 0.4
        ifelse any? mobs-on patch-ahead 1 [

          ;drain life
          set projectile-damage [hp] of one-of mobs-on patch-ahead 1
          print (word "You drain **" projectile-damage "** hp worth of life force out of your enemy and feel invigorated!")
          ask one-of heros [
            set hp hp + [projectile-damage] of myself
            set label (word "+" [projectile-damage] of myself)
          ]

          ;turn them yucky green
          ask one-of mobs-on patch-ahead 1 [
            create-drain-life-vector-to one-of heros
            ask drain-life-vectors [
              set color green
              set thickness 0.25
            ]
            set hp 0
            set color green
            wait 0.5
            check-for-death
            ask drain-life-vectors [die]
          ]
          die
        ][
          fd 1
        ]
      ]
      die
    ]

    ask one-of heros [set label ""]
  ]
end

to cast-sanctuary
  ask one-of heros [
    set magic-sanctuary (random (xp-level * 3)) + 10
    set mana mana - 5
    print (word "You feel the armor of God upon you.")
  ]
end

to cast-light

  print "You body glows with radiant light."


  ask heros [
    set mana mana - 1
    set vision 4
    if xp-level > 5 [set vision 5]
    if xp-level > 10 [set vision 6]
    if xp-level > 15 [set vision 7]
    set magic-light (random 25 + 25) * xp-level
  ]

  update-display

end

to cast-heal
  let heal-amount 0

  ask one-of heros [
    ifelse mana > 0 [
      repeat [xp-level] of self [
        set heal-amount heal-amount + random 6 + 1
      ]
      print (word "You healed your self for " heal-amount)
      set hp hp + heal-amount
    ][print "You do not have enough mana."]
  ]

  ask heros [set mana mana - 2]
end

to cast-smoke-screen
  let smoke-radius [xp-level] of one-of heros
  if smoke-radius > 5 [set smoke-radius 5]
  ask one-of heros [
    ask patches with [walkable? = true] in-radius smoke-radius [
      set smoke-screen-timer ticks + random ([xp-level] of one-of heros * 10) + 5
    ]
    ask heros [set mana mana - 2]
  ]
end

to cast-magic-missile

  ask one-of heros [
    hatch-projectiles 1 [
      set shape "arrow2"
      set color red
      set projectile-damage 0
      repeat [xp-level] of myself [
        set projectile-damage projectile-damage + (random 8 + 1)
      ]
      print (word "A magic missile springs forth from your fingertips.")
      set heading towards min-one-of mobs [distance myself]
    ]
    set mana mana - 1

    ;move projectile and attack roll
    ask one-of projectiles with [shape = "arrow2"] [
      repeat [xp-level * 2] of one-of heros [
        ifelse any? mobs-on patch-ahead 1 [battle self one-of mobs-on patch-ahead 1 ([xp-level] of one-of heros * 10) 5][fd 1]
        wait 0.05
      ]
      die
    ]
  ]

end

to cast-flame-tongue
  ask one-of heros [
    hatch-projectiles 1 [
      set shape "fire"
      set color red
      set projectile-damage 0
      repeat [xp-level] of myself [
        set projectile-damage projectile-damage + (random 10 + 1)
      ]
      print (word "A tongue of flame springs forth from your hands!")
      set heading towards min-one-of mobs [distance myself]

    ]
    set mana mana - 2

    ;move projectile and attack roll
    ask one-of projectiles with [shape = "fire"] [
      wait 0.4
      set size 2
      repeat 2 [
        wait 0.4
        ifelse any? mobs-on patch-ahead 1 [battle self one-of mobs-on patch-ahead 1 ([xp-level] of one-of heros * 10) 0][fd 1]
      ]
      die
    ]
  ]
end

to cast-sense-danger

  print "You feel the presence of danger."
  ask heros [
    set mana mana - 1
    set magic-sense-danger (random 10 + 1) * xp-level
  ]

end

to cast-enlightenment
  let light-radius [xp-level] of one-of heros + 5

  if light-radius > 10 [set light-radius 10]
  ask one-of heros [
    ask patches in-radius light-radius [
      set discovered? true
    ]
    set mana mana - 3
  ]
end

to cast-strength
  ask one-of heros [
    set magic-strength random (xp-level * 10) + 5
    set mana mana - 3
  ]
end

to cast-protection
  ask one-of heros [
    set magic-protection random (xp-level * 10) + 5
    set mana mana - 3
  ]
end

to cast-lightning-bolt
  let bolt-life random (([xp-level] of one-of heros) * 10) + 20 ;determines strength of bolt
  let bolt-damage 0

  ask one-of heros [
    hatch-projectiles 1 [
      set shape "lightning"
      set color yellow
      set projectile-damage 0
      repeat [xp-level] of myself [
        set projectile-damage projectile-damage + (random 6 + 1)
      ]
      print (word "A bolt of lightning shoots from your hands!")
      print (word "Bolt Life: " bolt-life)
    ]
    set mana mana - 4


    ask one-of projectiles with [shape = "lightning"] [
      while [bolt-life > 0] [
        ifelse count mobs > 0 [set heading towards min-one-of mobs [distance myself]][die stop]
        pen-down
        ifelse any? mobs-on patch-ahead 1 [
          ask one-of mobs-on patch-ahead 1 [
            if hp > bolt-life [set bolt-damage bolt-life]
            if bolt-life >= hp [set bolt-damage hp]
            set hp hp - bolt-damage
            set bolt-life bolt-life - bolt-damage
            check-for-death
          ]
          wait 0.2
          if bolt-life > 0 [set bolt-life bolt-life - 1]
          ifelse count mobs > 0 [set heading towards min-one-of mobs [distance myself]][die stop]

        ][
          set bolt-life bolt-life - 1
          if [walkable? = false] of patch-ahead 1 [set bolt-life 0]
          fd 1
          wait 0.2
        ]
      ]
    ]

    ask projectiles with [shape = "lightning"] [die]
  ]
  clear-drawing
end

to cast-magic-fire
  ask one-of heros [
    set magic-fire random (xp-level * 10)
    set mana mana - 4
  ]
end

to cast-dexterity
  ask one-of heros [
    set magic-dexterity random (xp-level * 3) + 10
    set mana mana - 4
  ]
end

to cast-spell
  let this-spell-level 0
  let spell-to-be-cast user-input "Cast your spell hero:"
  let can-cast? true

  if spell-to-be-cast = "mil" [set this-spell-level 1]
  if spell-to-be-cast = "sns" [set this-spell-level 1]
  if spell-to-be-cast = "lit" [set this-spell-level 1]

  if spell-to-be-cast = "flt" [set this-spell-level 2]
  if spell-to-be-cast = "hle" [set this-spell-level 2]
  if spell-to-be-cast = "sms" [set this-spell-level 2]

  if spell-to-be-cast = "enlight" [set this-spell-level 3]
  if spell-to-be-cast = "str" [set this-spell-level 3]
  if spell-to-be-cast = "prot" [set this-spell-level 3]

  if spell-to-be-cast = "bolt" [set this-spell-level 4]
  if spell-to-be-cast = "mfir" [set this-spell-level 4]
  if spell-to-be-cast = "dex" [set this-spell-level 4]

  if spell-to-be-cast = "snc" [set this-spell-level 5]
  if spell-to-be-cast = "drn" [set this-spell-level 5]
  if spell-to-be-cast = "wlk" [set this-spell-level 5]

  if spell-to-be-cast = "fbl" [set this-spell-level 6]
  if spell-to-be-cast = "slp" [set this-spell-level 6]
  if spell-to-be-cast = "tel" [set this-spell-level 6]

  if spell-to-be-cast = "xxx" [set this-spell-level 7]
  if spell-to-be-cast = "ded" [set this-spell-level 7]
  if spell-to-be-cast = "create" [set this-spell-level 7]

  ask one-of heros [
    if mana < this-spell-level [
      print "You do not have enough mana."
      set can-cast? false
    ]

    if [smoke-screen-timer > ticks] of patch-here [
      print "You stumble trying to cast your spell in the smoke."
      set mana mana - this-spell-level
      set can-cast? false
    ]
  ]

  if can-cast? = true [
    if spell-to-be-cast = "mil" and spell-magic-missile = 1 [cast-magic-missile]
    if spell-to-be-cast = "flt" and spell-flame-tongue = 1 [cast-flame-tongue]
    if spell-to-be-cast = "sms" and spell-smoke-screen = 1 [cast-smoke-screen]
    if spell-to-be-cast = "hle" and spell-heal = 1 [cast-heal]
    if spell-to-be-cast = "lit" and spell-light = 1 [cast-light]
    if spell-to-be-cast = "sns" and spell-sense-danger = 1 [cast-sense-danger]
    if spell-to-be-cast = "enlight" and spell-enlightenment = 1 [cast-enlightenment]
    if spell-to-be-cast = "str" and spell-strength = 1 [cast-strength]
    if spell-to-be-cast = "prot" and spell-protection = 1 [cast-protection]
    if spell-to-be-cast = "bolt" and spell-lightning-bolt = 1 [cast-lightning-bolt]
    if spell-to-be-cast = "mfir" and spell-magic-fire = 1 [cast-magic-fire]
    if spell-to-be-cast = "dex" and spell-dexterity = 1 [cast-dexterity]
    if spell-to-be-cast = "snc" and spell-sanctuary = 1 [cast-sanctuary]
    if spell-to-be-cast = "drn" and spell-drain-life = 1 [cast-drain-life]
    if spell-to-be-cast = "wlk" and spell-walk-through-walls = 1 [cast-walk-through-walls]
    if spell-to-be-cast = "fbl" and spell-fireball = 1 [cast-fireball]
    if spell-to-be-cast = "slp" and spell-sleep = 1 [cast-sleep]
    if spell-to-be-cast = "tel" and spell-teleport = 1 [cast-teleport]
    if spell-to-be-cast = "xxx" and spell-sphere-of-annihilation = 1 [cast-sphere-of-annihilation]
    if spell-to-be-cast = "ded" and spell-sleep = 1 [cast-animate-dead]
    if spell-to-be-cast = "create" and spell-sleep = 1 [cast-create-item]
  ]

  move "rest"

end

to setup
  clear-all
  clear-output
  clear-patches
  clear-turtles
  reset-ticks

  set level 1

  while [level <= 20] [
    generate-tunnel-level level
    save-level word "cave-" level
    set level level + 1
  ]

  set level "surface"

  generate-surface-level
  generate-hero
  generate-citizens 10

  update-display

  ;highlight where the hero is
  ask heros [
    repeat 5 [
      set size 5
      wait 0.3
      set size 1
      wait 0.1
    ]
  ]

end

to update-display

  let display-cursor-x -16
  let display-cursor-y 16

  ;
  ask patches with [pycor > 14] [
    set discovered? true
    set walkable? false
    set pcolor 9
  ]


  ;hp bar (draw red first, then overlay green)
  if count heros > 0 [

    ifelse [hp] of one-of heros <= 66 [
      repeat [max-hp] of one-of heros [
        ask patch display-cursor-x display-cursor-y [set pcolor red]
        ifelse display-cursor-x < 16 [
          set display-cursor-x display-cursor-x + 1
        ][
          set display-cursor-x -16
          set display-cursor-y 15
        ]
      ]

      set display-cursor-x -16
      set display-cursor-y 16

      repeat [hp] of one-of heros [
        ask patch display-cursor-x display-cursor-y [set pcolor green]
        ifelse display-cursor-x < 16 [
          set display-cursor-x display-cursor-x + 1
        ][
          set display-cursor-x -16
          set display-cursor-y 15
        ]
      ]
    ][
      ask patches with [pycor = 16] [set pcolor green]
      ask patches with [pycor = 15] [set pcolor green]
      ask patch 16 15 [set plabel [hp] of one-of heros]
    ]
  ]


  ;update spell list
  clear-output
  if spell-magic-missile = 1 [output-print "[1] mil - Magic Missile"]
  if spell-sense-danger = 1 [output-print "[1] sns - Sense Danger"]
  if spell-light = 1 [output-print "[1] lit - Light"]

  output-print " "

  if spell-flame-tongue = 1 [output-print "[2] flt - Flame Tongue"]
  if spell-heal = 1 [output-print "[2] hle - Heal"]
  if spell-smoke-screen = 1 [output-print "[2] sms - Smoke Screen"]

  output-print " "

  if spell-enlightenment = 1 [output-print "[3] enlight - Enlightenment"]
  if spell-strength = 1 [output-print "[3] str - Strength"]
  if spell-protection = 1 [output-print "[3] prot - Protection"]

  output-print " "

  if spell-lightning-bolt = 1 [output-print "[4] bolt - Lightning Bolt"]
  if spell-magic-fire = 1 [output-print "[4] mfir - Magic Fire"]
  if spell-dexterity = 1 [output-print "[4] dex - Dexterity"]

  output-print " "

  if spell-sanctuary = 1 [output-print "[5] snc - Sanctuary"]
  if spell-drain-life = 1 [output-print "[5] drn - Drain Life"]
  if spell-walk-through-walls = 1 [output-print "[5] wlk - Walk Through Walls"]

  output-print " "

  if spell-fireball = 1 [output-print "[6] fbl - Fireball"]
  if spell-sleep = 1 [output-print "[6] slp - Sleep"]
  if spell-teleport = 1 [output-print "[6] tel - Teleport"]

  output-print " "

  if spell-sphere-of-annihilation = 1 [output-print "[7] xxx - Sphere of Annihilation"]
  if spell-animate-dead = 1 [output-print "[7] ded - Animate Dead"]
  if spell-create-item = 1 [output-print "[7] create - Create Item"]


  ;discover patches
  carefully [
    ask one-of heros [
      ask patches in-radius vision [
        set discovered? true
      ]
      ask patch-here [set discovered? true]
    ]
  ][]


  ;update patch colors
  ask patches with [discovered? = false] [set pcolor 2]
  ask patches with [discovered? = true and pycor < 15] [
    if smoke-screen-timer > ticks [set pcolor 49]
    if smoke-screen-timer <= ticks and walkable? = true [set pcolor black]
    if smoke-screen-timer <= ticks and walkable? = false [set pcolor grey]

    ;fireball timers get set last.  So, if a patch has smokescreen and fire, it will show fire
    if fireball-timer > ticks [set pcolor red]
    if fireball-timer <= ticks and walkable? = true [set pcolor black]
    if fireball-timer <= ticks and walkable? = false [set pcolor grey]
  ]


  ;update spell enchantments on display
  if any? heros [

    ;magic light
    ask patch -13 15 [
      ifelse [magic-light] of one-of heros > 0 [
        set plabel-color black
        set plabel (word "Light: " [magic-light] of one-of heros)
        ask one-of heros [set color 47]
      ][
        set plabel ""
      ]
    ]


    ;sense danger
    ask patch -10 15 [
      ifelse [magic-sense-danger] of one-of heros > 0 [
        set plabel-color black
        set plabel (word "Danger: " [magic-sense-danger] of one-of heros)
      ][
        set plabel ""
      ]
    ]


    ;strength
    ask patch -7 15 [
      ifelse [magic-strength] of one-of heros > 0 [
        set plabel-color black
        set plabel (word "Str: " [magic-strength] of one-of heros)
      ][
        set plabel ""
      ]
    ]

    ;protection
    ask patch -4 15 [
      ifelse [magic-protection] of one-of heros > 0 [
        set plabel-color black
        set plabel (word "Prot: " [magic-protection] of one-of heros)
      ][
        set plabel ""
      ]
    ]

    ;magic fire
    ask patch -1 15 [
      ifelse [magic-fire] of one-of heros > 0 [
        set plabel-color black
        set plabel (word"Fire: " [magic-fire] of one-of heros)
        ask one-of heros [set color 129]
      ][
        set plabel ""
        ask one-of heros [set color orange]
      ]
    ]

    ;magic dexterity
    ask patch 2 15 [
      ifelse [magic-dexterity] of one-of heros > 0 [
        set plabel-color black
        set plabel (word "Dexterity: " [magic-dexterity] of one-of heros)
      ][
        set plabel ""
      ]
    ]

    ;show danger
    if [magic-sense-danger] of one-of heros > 0 [
      ;mobs
      ask mobs [
        ask patch-here [set pcolor red]
      ]

      ;boobytraps and trap-doors
      ask patches with [boobytrap? = true or trap-door? = true] [
        set pcolor red
      ]

      ;trapped treasure chests
      ask treasure-chests with [trapped? = true] [
        ask patch-here [set pcolor red]
      ]
    ]

    ;sanctuary
    ask patch 5 15 [
      ifelse [magic-sanctuary] of one-of heros > 0 [
        set plabel-color black
        set plabel (word "Sanctuary: " [magic-sanctuary] of one-of heros)
      ][
        set plabel ""
      ]
    ]

    ;walk through walls
    ask patch 8 15 [
      ifelse [magic-walk-through-walls] of one-of heros > 0 [
        set plabel-color black
        set plabel (word "Walk Through Walls: " [magic-walk-through-walls] of one-of heros)
      ][
        set plabel ""
      ]
    ]


  ]

  ;hide coins and items if a mob is on the same square
  ask patches with [discovered? = true] [
    ask treasures-here [
      ifelse any? mobs-here [set hidden? true] [set hidden? false]
    ]
    ask weapons-here [
      ifelse any? mobs-here [set hidden? true] [set hidden? false]
    ]
    ask armors-here [
      ifelse any? mobs-here [set hidden? true] [set hidden? false]
    ]
    ask torches-here [
      ifelse any? mobs-here [set hidden? true] [set hidden? false]
    ]
  ]

  ;hide stuff in non-discovered patches
  if level != "surface" [
    ask turtles [
      ifelse [discovered? = true] of patch-here [set hidden? false][set hidden? true]
    ]
  ]

end

to wear-gear
ask armors with [armor-used = 1] [
    move-to one-of heros
  ]

  ask weapons with [weapon-type = "hand" and weapon-used = 1] [
    move-to one-of heros
    set heading 90
    fd 0.2
    set heading 15
  ]

  ask weapons with [weapon-type = "ranged" and weapon-used = 1] [
    move-to one-of heros
    set heading 270
    fd 0.2
    set heading 180
  ]

  ask torches with [torch-used = 1] [
    move-to one-of heros
    set heading 140
    fd -0.5
  ]

end

to move [dir]

  tick
  heal

  if dir = "north" [ask heros [set heading 0]]
  if dir = "south" [ask heros [set heading 180]]
  if dir = "east" [ask heros [set heading 90]]
  if dir = "west" [ask heros [set heading 270]]

  if dir = "north-west" [ask heros [set heading 315]]
  if dir = "north-east" [ask heros [set heading 45]]
  if dir = "south-west" [ask heros [set heading 225]]
  if dir = "south-east" [ask heros [set heading 135]]


  ask heros [
    ifelse (dir != "rest") and
    (can-move? 1) and
    ([walkable? = true] of patch-ahead 1 or magic-walk-through-walls > 0) and ;this line lets heros attack mobs that are floating through walls
    (any? (mobs-on patch-ahead 1) with [master = 0]) [

      ;do battle
      battle self one-of (mobs-on patch-ahead 1) with [master = 0] 0 0

    ][
      if (dir != "rest") and
      (can-move? 1) and
      ([walkable? = true] of patch-ahead 1 or magic-walk-through-walls > 0) and
      [pycor < 15] of patch-ahead 1 [
        fd 1
        set xcor round xcor
        set ycor round ycor
      ]
    ]

    if [fireball-timer] of patch-here > ticks [
      let fireball-damage (random (xp-level * 6) + xp-level)
      set hp hp - fireball-damage
      ;some cool graphics
      set size 5
      set label-color white
      set label fireball-damage
      wait 0.5
      set size 1
      set label ""
      check-for-death
    ]
  ]

  if any? heros [wear-gear]

  burn-torches
  update-spell-enchantments

  ;move citizens or mobs depending on where we're at
  move-citizens
  move-mobs
  ;ifelse level = "surface" [move-citizens][move-mobs]

  ask heros [check-for-level-up]

  if count heros > 0 [check-whats-here]

  update-display
end

to update-spell-enchantments

  ask one-of heros [
    if magic-light > 0 [set magic-light magic-light - 1]
    if magic-strength > 0 [set magic-strength magic-strength - 1]
    if magic-protection > 0 [set magic-protection magic-protection - 1]
    if magic-fire > 0 [set magic-fire magic-fire - 1]
    if magic-dexterity > 0 [set magic-dexterity magic-dexterity - 1]
    if magic-sense-danger > 0 [set magic-sense-danger magic-sense-danger - 1]
    if magic-sanctuary > 0 [set magic-sanctuary magic-sanctuary - 1]

    if magic-walk-through-walls > 0 [
      set magic-walk-through-walls magic-walk-through-walls - 1
      if magic-walk-through-walls = 0 [check-for-death]
    ]
  ]

end

to burn-torches

  if any? torches with [torch-used = 1] [
    ask one-of heros [
      if magic-light = 0 [set vision 4]
    ]

    ask torches with [torch-used = 1] [
      set torch-timer torch-timer - 1

      ;adjust color based on burn timer
      if torch-timer >= 60 [set color 45]
      if torch-timer > 20 and torch-timer < 60 [set color 25]
      if torch-timer < 20 [set color 15]

      ;torch burns out
      if torch-timer < 1 [
        print "Your torch burns out."
        ask one-of heros [
          if magic-light < 1 [set vision 2]
        ]
        die
      ]
    ]
  ]
end

to check-for-level-up

  let level-up false

  ask one-of heros [
    if xp-level = 1 and xp >= 250 and xp <= 500 [set level-up true]
    if xp-level = 2 and xp >= 501 and xp <= 1000 [set level-up true]
    if xp-level = 3 and xp >= 1001 and xp <= 2000 [set level-up true]
    if xp-level = 4 and xp >= 2001 and xp <= 4000 [set level-up true]
    if xp-level = 5 and xp >= 4001 and xp <= 8000 [set level-up true]
    if xp-level = 6 and xp >= 8001 and xp <= 16000 [set level-up true]
    if xp-level = 7 and xp >= 16001 and xp <= 32000 [set level-up true]
    if xp-level = 8 and xp >= 32001 and xp <= 64000 [set level-up true]
    if xp-level = 9 and xp >= 64001 and xp <= 128000 [set level-up true]
    if xp-level = 10 and xp >= 128001 and xp <= 256000 [set level-up true]
    if xp-level = 11 and xp >= 256001 and xp <= 512000 [set level-up true]
    if xp-level = 12 and xp >= 512001 and xp <= 1024000 [set level-up true]
  ]

  if level-up = true [
    set max-hp max-hp + random 8 + 1
    set hp max-hp
    set xp-level xp-level + 1
    if xp-level mod 2 = 0 [
      set max-mana max-mana + 1
      set mana max-mana
    ]
    set size 2
    wait 0.2
    set size 3
    wait 0.2
    set size 4
    wait 0.2
    set size 5
    wait 0.2
    set size 1
  ]


end

to heal
  if ticks mod 10 = 0 [
    ask turtles with [breed = heros or breed = mobs] [
      if hp < max-hp [set hp hp + heal-rate]
      if hp > max-hp [set hp hp - 1]
    ]
  ]

  if ticks mod 20 = 0 [
    ask heros [
      if mana < max-mana [set mana mana + 1]
      if mana > max-mana [set mana max-mana]
    ]
  ]
end

to check-for-death
  let coin-drop 0
  let drop-chance 0

  ask one-of heros [
    if (hp <= 0) or ([walkable? = false] of patch-here and magic-walk-through-walls = 0) [
      user-message ("You have died!")
      die
    ]
  ]

  ask mobs with [hp <= 0] [

    ;all the stuff to do if it's a normal monster
    if master = 0 [
      set coin-drop [xp] of self

      print (word "You gain " xp " XP.")

      ask heros [set xp xp + [xp] of myself]

      ask neighbors with [walkable? = true] [
        set drop-chance random 100 + 1

        if drop-chance >= 0 and drop-chance <= 20 [
          sprout-treasures 1 [
            set coins random coin-drop + 1
            set color 45
            set shape "coin"
          ]
        ]

        if drop-chance >= 21 and drop-chance <= 25 [
          drop-item self level
        ]
      ]
      ;visual effects of the mob dying
      set label (word xp " XP gained!")
    ]

    ;death graphics applicable to all mobs
    let j 1
    facexy 0 0
    repeat 100 [
      fd 0.02
      set size j
      wait 0.01
      set j j + 0.05
    ]
    die
  ]

end

to battle [attacker defender attacker-hitroll attacker-damage]
  ;
  ;this procedure executes one round of battle
  ;hitrolls are modifiers to the chance to hit.  Base chance is 50%
  ;

  ;lose sanctuary if attacking
  if [breed] of attacker != projectiles [
    ask attacker [
      if magic-sanctuary > 0 [
        print "The armor of God fades away as you attack your enemy out of anger."
        set magic-sanctuary 0
      ]
    ]
  ]

  ; check to make sure defender isn't hiding in a wall (ex. ghasts, and other stuff in the future)
  let hitable? false
  ask defender [
    ifelse [walkable? = false] of patch-here [
      set hitable? false
    ][set hitable? true]
  ]

  let defender-armor [armor-value] of defender
  let attack-roll random 100 + 1
  ;print (word "Raw Attack Roll: " attack-roll)
  let battle-damage 0


  ;adjust for magic dexterity enchantment
  set defender-armor defender-armor + [magic-dexterity] of defender
  set attack-roll attack-roll + [magic-dexterity] of attacker

  ;adjust for magic strength enchantment
  set attacker-damage attacker-damage + [magic-strength] of attacker

  ;adjust for magic protection enchantment
  set defender-armor defender-armor + [magic-protection] of defender

  ;final calc of attack roll
  set attack-roll attack-roll - defender-armor + attacker-hitroll


  ;show calculations for debuging and game testing
  ;print (word "Attacker Hitroll Bonus: " attacker-hitroll)
  ;print (word "Attacker Damage Bonus: " attacker-damage)
  ;print (word "Defender Armor: " defender-armor)
  ;print (word "Final Attack Roll: " attack-roll)

  ;check for a projectile first
  if [breed] of attacker = projectiles [

    if attack-roll >= 50 and hitable? = true and [magic-sanctuary] of defender = 0 [
      ;lose sanctuary if attacking
      if [breed] of attacker != projectiles [ask attacker [set magic-sanctuary 0]]

      set battle-damage (random [projectile-damage] of attacker + 1) + attacker-damage
      print (word defender " suffers " battle-damage " points of damage.")

      ask defender [
        set hp hp - battle-damage
        set size 5
        set label-color white
        set label battle-damage
        wait 0.2
        set size 1
        set label ""
      ]

      if [shape != "lightning"] of attacker [ask attacker [die]]
    ]
  ]

  ;reguar melee
  ifelse attack-roll >= 50 and [breed] of attacker != projectiles and hitable? = true and [magic-sanctuary] of defender = 0 [
    ;attack successful
    set battle-damage random [damage] of attacker + 1
    set battle-damage battle-damage + [magic-strength] of attacker
    ask defender [set hp hp - battle-damage]
    print (word attacker " successfully attacks " defender " for " battle-damage " damage!")
    ask defender [
      set size 5
      set label-color white
      set label battle-damage
      wait 0.2
      set size 1
      set label ""
    ]

    ;check for magic fire
    if [magic-fire > 0] of defender [
      ask attacker [set hp hp - battle-damage]
      ask attacker [
        set size 5
        set label-color white
        set label (word "Magic Fire!!! " battle-damage)
        wait 0.5
        set size 1
        set label ""
      ]
    ]
  ][
    print (word attacker " failed to attack " defender)
  ]

  ;print (word "Remaining " defender " HP: " [hp] of defender)
  check-for-death

end

to save-level [name]

  let filepath (word "tunnelworld-" name ".csv")
  export-world filepath

end

to load-level [name move-type]
  ;creating these local variables ensures the values persist through a load/save event
  let temp-hp [hp] of one-of heros
  let temp-damage [damage] of one-of heros
  let temp-magic-light [magic-light] of one-of heros
  let temp-magic-strength [magic-strength] of one-of heros
  let temp-magic-protection [magic-protection] of one-of heros
  let temp-magic-dexterity [magic-dexterity] of one-of heros
  let temp-magic-sense-danger [magic-sense-danger] of one-of heros
  let temp-magic-sanctuary [magic-sanctuary] of one-of heros
  let temp-magic-walk-through-walls [magic-walk-through-walls] of one-of heros
  let temp-in-hand [in-hand] of one-of heros
  let temp-max-hp [max-hp] of one-of heros
  let temp-mana [mana] of one-of heros
  let temp-max-mana [max-mana] of one-of heros
  let temp-xp [xp] of one-of heros
  let temp-heal-rate [heal-rate] of one-of heros
  let temp-gold [gold] of one-of heros
  let temp-xp-level [xp-level] of one-of heros
  let temp-vision [vision] of one-of heros
  let temp-ticks ticks

  let temp-weapon-name 0
  let temp-weapon-damage 0
  let temp-weapon-cost 0
  let temp-weapon-used 0
  let temp-weapon-shape 0
  let temp-weapon-color 0

  let temp-ranged-weapon-name 0
  let temp-ranged-weapon-damage 0
  let temp-ranged-weapon-ammo 0
  let temp-ranged-weapon-cost 0
  let temp-ranged-weapon-used 0
  let temp-ranged-weapon-shape 0
  let temp-ranged-weapon-color 0

  let temp-armor-name 0
  let temp-armor-value 0
  let temp-armor-cost 0
  let temp-armor-used 0
  let temp-armor-shape 0
  let temp-armor-color 0

  let temp-torch-timer 0
  let temp-torch-used 0
  let temp-torch-color 0

  ;capture global values so they can be reloaded
  let temp-spell-magic-missile spell-magic-missile
  let temp-spell-flame-tongue spell-flame-tongue
  let temp-spell-heal spell-heal
  let temp-spell-smoke-screen spell-smoke-screen
  let temp-spell-light spell-light
  let temp-spell-sense-danger spell-sense-danger
  let temp-spell-enlightenment spell-enlightenment
  let temp-spell-strength spell-strength
  let temp-spell-protection spell-protection
  let temp-spell-lightning-bolt spell-lightning-bolt
  let temp-spell-magic-fire spell-magic-fire
  let temp-spell-dexterity spell-dexterity
  let temp-spell-sanctuary spell-sanctuary
  let temp-spell-drain-life spell-drain-life
  let temp-spell-walk-through-walls spell-walk-through-walls
  let temp-spell-fireball spell-fireball
  let temp-spell-sleep spell-sleep
  let temp-spell-sphere-of-annihilation spell-sphere-of-annihilation

  ;save armor details
  if any? armors with [armor-used = 1] [
    ask armors with [armor-used = 1] [
      set temp-armor-name [armor-name] of self
      set temp-armor-value [armor-value] of self
      set temp-armor-cost [armor-cost] of self
      set temp-armor-shape [shape] of self
      set temp-armor-color [color] of self
      set temp-armor-used 1
    ]
  ]


  ;save weapon details
  if any? weapons with [weapon-type = "hand" and weapon-used = 1] [
    ask weapons with [weapon-type = "hand" and weapon-used = 1] [
      set temp-weapon-name [weapon-name] of self
      set temp-weapon-damage [weapon-damage] of self
      set temp-weapon-cost [weapon-cost] of self
      set temp-weapon-shape [shape] of self
      set temp-weapon-color [color] of self
      set temp-weapon-used 1
    ]
  ]

  ;save ranged weapon details
  if any? weapons with [weapon-type = "ranged" and weapon-used = 1] [
    ask weapons with [weapon-type = "ranged" and weapon-used = 1] [
      set temp-ranged-weapon-name [weapon-name] of self
      set temp-ranged-weapon-damage [weapon-damage] of self
      set temp-ranged-weapon-ammo [weapon-ammo] of self
      set temp-ranged-weapon-cost [weapon-cost] of self
      set temp-ranged-weapon-shape [shape] of self
      set temp-ranged-weapon-color [color] of self
      set temp-ranged-weapon-used 1
    ]
  ]

  ;save torch details
  if any? torches with [torch-used = 1] [
    ask torches with [torch-used = 1] [
      set temp-torch-timer [torch-timer] of self
      set temp-torch-used 1
      set temp-torch-color [color] of self
    ]
  ]

  let filepath (word "tunnelworld-" name ".csv")
  import-world filepath

  ask heros [die]

  ;place the hero depending on if he's falling through a trapdoor or climbing down the ladder
  if move-type = "trap-door" [
    let valid-landing-spot false
    create-heros 1 [
      while [valid-landing-spot = false] [
        setxy round random-xcor round random-ycor
        if ([walkable? = true] of patch-here or magic-walk-through-walls > 0) and [pycor < 15] of patch-here and not any? other turtles-here [set valid-landing-spot true]
      ]
        set shape "person"
        set color orange
      ]
  ]

  if move-type = "upshaft" [
    create-heros 1 [
      ifelse level != "surface" [
        set xcor [xcor] of one-of buildings with [building-type = "downshaft"]
        set ycor [ycor] of one-of buildings with [building-type = "downshaft"]
      ][
        set xcor [xcor] of one-of buildings with [building-type = "cave"]
        set ycor [ycor] of one-of buildings with [building-type = "cave"]
      ]
      set shape "person"
      set color orange
    ]
  ]

  if move-type = "downshaft" or move-type = "cave" [
    create-heros 1 [
      ifelse level != "surface" [
        set xcor [xcor] of one-of buildings with [building-type = "upshaft"]
        set ycor [ycor] of one-of buildings with [building-type = "upshaft"]
      ][
        set xcor [xcor] of one-of buildings with [building-type = "cave"]
        set ycor [ycor] of one-of buildings with [building-type = "cave"]
      ]
      set shape "person"
      set color orange
    ]
  ]


  ask weapons with [weapon-used = 1] [die]
  ask armors with [armor-used = 1] [die]
  ask torches with [torch-used = 1] [die]

  ;load armor details
  if temp-armor-name != 0 [
    create-armors 1 [
      set armor-name temp-armor-name
      set armor-value temp-armor-value
      set armor-cost temp-armor-cost
      set armor-used 1
      set shape temp-armor-shape
      set color temp-armor-color
    ]
  ]

  ;load weapon details
  if temp-weapon-name != 0 [
    create-weapons 1 [
      set weapon-type "hand"
      set weapon-name temp-weapon-name
      set weapon-damage temp-weapon-damage
      set weapon-cost temp-weapon-cost
      set weapon-used 1
      set shape temp-weapon-shape
      set color temp-weapon-color
    ]
  ]

  ;load ranged weapon details
  if temp-ranged-weapon-name != 0 [
    create-weapons 1 [
      set weapon-type "ranged"
      set weapon-name temp-ranged-weapon-name
      set weapon-damage temp-ranged-weapon-damage
      set weapon-ammo temp-ranged-weapon-ammo
      set weapon-cost temp-ranged-weapon-cost
      set weapon-used 1
      set shape temp-ranged-weapon-shape
      set color temp-ranged-weapon-color
    ]
  ]

  ;load torch
  if temp-torch-used = 1 [
    create-torches 1 [
      set torch-timer temp-torch-timer
      set torch-used 1
      set shape "torch"
      set color temp-torch-color
    ]
  ]


  ; reload spells
  set spell-magic-missile temp-spell-magic-missile
  set spell-flame-tongue temp-spell-flame-tongue
  set spell-heal temp-spell-heal
  set spell-smoke-screen temp-spell-smoke-screen
  set spell-light temp-spell-light
  set spell-sense-danger temp-spell-sense-danger
  set spell-enlightenment temp-spell-enlightenment
  set spell-strength temp-spell-strength
  set spell-protection temp-spell-protection
  set spell-lightning-bolt temp-spell-lightning-bolt
  set spell-magic-fire temp-spell-magic-fire
  set spell-dexterity temp-spell-dexterity
  set spell-sanctuary temp-spell-sanctuary
  set spell-walk-through-walls temp-spell-walk-through-walls
  set spell-drain-life temp-spell-drain-life
  set spell-fireball temp-spell-fireball
  set spell-sleep temp-spell-sleep
  set spell-sphere-of-annihilation temp-spell-sphere-of-annihilation

  update-display

  reset-ticks
  tick-advance temp-ticks

  ;reinit all hero variables
  ask heros [
    set hp temp-hp
    set armor-name temp-armor-name
    set armor-value temp-armor-value
    set damage temp-damage
    set magic-light temp-magic-light
    set magic-sense-danger temp-magic-sense-danger
    set magic-strength temp-magic-strength
    set magic-protection temp-magic-protection
    set magic-dexterity temp-magic-dexterity
    set magic-sanctuary temp-magic-sanctuary
    set magic-walk-through-walls temp-magic-walk-through-walls
    set in-hand temp-in-hand
    set max-hp temp-max-hp
    set heal-rate temp-heal-rate
    set mana temp-mana
    set max-mana temp-max-mana
    set xp temp-xp
    set xp-level temp-xp-level
    set gold temp-gold
    set vision temp-vision
  ]

  ;take damage from falling through the trap door
  if move-type = "trap-door" [
    let trap-door-damage random 10 + 1
    ask one-of heros [
      set hp hp - trap-door-damage
      print (word "You took " trap-door-damage " damage falling through the trap door!")
      if hp <= 0 [set hp 1] ;never die from a trap door
    ]
  ]

end

to generate-hero
  create-heros 1 [
    setxy round random-xcor round random-ycor
    set shape "person"
    set color orange
    set in-hand "nothing"
    set armor-name "clothes"
    set armor-value 5
    set vision 2
    set damage 1
    set magic-strength 0
    set magic-protection 0
    set magic-dexterity 0
    set magic-sanctuary 0
    set magic-walk-through-walls 0
    set hp 10
    set max-hp hp
    set mana 1
    set max-mana 1
    set heal-rate 1
    set gold 250
    set xp-level 1
  ]

  ask heros [if ycor > 14 [set ycor 14]]
end

to generate-citizens [population]

  create-citizens population [
    set shape "person"
    set color gray
    setxy round random-xcor round random-ycor
  ]

  ask citizens [
    if ycor > 14 [
      set ycor 14
    ]
  ]
end

to generate-wolf-pack

  ask one-of patches with [walkable? = true] [
    sprout-mobs 1 [
      set mob-name "dire wolf"
      set hp 0
      repeat level [set hp hp + random 6 + 1]
      set max-hp hp
      set heal-rate 1
      set armor-value random 30 + 1
      set shape "dire wolf"
      set damage 0
      repeat level [set damage damage + random 8 + 1]
      set mob-speed 2
      set xp ((hp + armor-value) * damage)
    ]

    ask neighbors with [walkable? = true] [
      sprout-mobs 1 [
        set mob-name "dire wolf"
        set hp 0
        repeat level [set hp hp + random 6 + 1]
        set max-hp hp
        set heal-rate 1
        set armor-value random 30 + 1
        set shape "dire wolf"
        set damage 0
        repeat level [set damage damage + random 8 + 1]
        set mob-speed 2
        set xp ((hp + armor-value) * damage)
      ]
    ]
  ]

end

to generate-boss-mob
ask one-of patches with [walkable? = true and pycor < 15] [
        sprout-mobs 1 [
          set mob-name "boss"
          set hp 0
          set hp hp + ((level * 25) + (random 100))
          set max-hp hp
          set heal-rate 1
          set armor-value random 20 + 1
          set shape "boss"
          set damage 0
          repeat level [set damage damage + random 6 + 1]
          set mob-speed 1
          set xp ((hp + armor-value) * damage)
        ]
      ]
end

to generate-mob [mob-qty]
  let mob-chance 0

  repeat mob-qty [
    if level = 1 [set mob-chance random 3 + 1]
    if level = 2 [set mob-chance random 5 + 1]
    if level >= 3 [set mob-chance random 6 + 1]

    ask one-of patches with [walkable? = true and pycor < 15] [
      if mob-chance = 1 [
        sprout-mobs 1 [
          set mob-name "hobgoblin"
          set hp 0
          repeat level [set hp hp + random 8 + 1]
          set max-hp hp
          set heal-rate 1
          set armor-value random 20 + 1
          set shape "person soldier"
          set color 95
          set damage 0
          set damage damage + random 6 + 1
          set mob-speed 1
          set xp ((hp + armor-value) * damage)
        ]
      ]

      if mob-chance = 2 [
        sprout-mobs 1 [
          set mob-name "giant larva"
          set hp 0
          repeat level [set hp hp + random 8 + 1]
          set max-hp hp
          set heal-rate 1
          set armor-value random 10 + 1
          set shape "bug"
          set damage 0
          set damage damage + random 6 + 1
          set mob-speed 1
          set xp ((hp + armor-value) * damage)
        ]
      ]

      if mob-chance = 3 [
        sprout-mobs 1 [
          set mob-name "dire wolf"
          set hp 0
          repeat level [set hp hp + random 10 + 1]
          set max-hp hp
          set heal-rate 1
          set armor-value random 30 + 1
          set shape "dire wolf"
          set damage 0
          set damage damage + random 6 + 1
          set mob-speed 2
          set xp ((hp + armor-value) * damage)
        ]
      ]

      if mob-chance = 4 [
        sprout-mobs 1 [
          set mob-name "cave bat"
          set hp 0
          repeat level [set hp hp + random 6 + 1]
          set max-hp hp
          set heal-rate 1
          set armor-value random 15 + 1
          set shape "cave bat"
          set damage 0
          set damage damage + random 6 + 1
          set mob-speed 1
          set xp ((hp + armor-value) * damage)
        ]
      ]

      if mob-chance = 5 [
        sprout-mobs 1 [
          set mob-name "giant caterpillar"
          set hp 0
          repeat level [set hp hp + random 16 + 1]
          set max-hp hp
          set heal-rate 1
          set armor-value random 35 + 1
          set shape "caterpillar"
          set damage 0
          set damage damage + random 4 + 1
          set mob-speed 1
          set xp ((hp + armor-value) * damage)
        ]
      ]

      if mob-chance = 6 [
        sprout-mobs 1 [
          set mob-name "ghast"
          set hp 0
          repeat level [set hp hp + random 18 + 1]
          set max-hp hp
          set heal-rate 1
          set armor-value random 35 + 1
          set shape "ghast"
          set damage 0
          set damage damage + random 4 + 1
          set mob-speed 1
          set magic-walk-thru-walls 1
          set xp ((hp + armor-value) * damage)
        ]
      ]




    ]
  ]

  ;store color value for later use (sleep spell, etc)
  ask mobs [
    set mob-color color
  ]
end

to build-house

  let can-build-house? true
  let cost-of-house 2500

  ask one-of heros [
    if gold < cost-of-house [
      user-message "You don't have enough gold."
      set can-build-house? false
    ]
  ]

  if level = "surface" and can-build-house? = true [
    ask one-of heros [

      user-message "You built a rental house!"

      ask patch-here [
        if not any? buildings-here [
          sprout-buildings 1 [
            set shape "house"
            set building-type "rental-house"
            set color green
            if any? other buildings-here [fd 3]
          ]
        ]
      ]

      set gold gold - cost-of-house

    ]
  ]

end

to move-citizens

  ask citizens [
    if random 10 + 1 > 9 [
      set heading random 360 + 1
      if (can-move? 1) and [pycor < 15 and walkable? = true] of patch-ahead 1 [
        fd 1
        set xcor round xcor
        set ycor round ycor
      ]
    ]
  ]

end

to move-mobs
  let has-attacked? false
  let fireball-damage-factor [xp-level] of one-of heros
  let fireball-damage (random (fireball-damage-factor * 6) + fireball-damage-factor)

  ;things to do for all non-hero life forms
  ask mobs [
    ;determine if mob should be visible
    ifelse [discovered? = true] of patch-here [set hidden? false][set hidden? true]

    ;check for fireball damage
    if [fireball-timer] of patch-here > ticks [
      set hp hp - (random (fireball-damage-factor * 6) + fireball-damage-factor)
      ;some cool graphics
      set size 5
      set label-color white
      set label fireball-damage
      wait 0.5
      set size 1
      set label ""
      check-for-death
    ]
  ]

  ;move the monsters
  ask mobs with [master = 0] [
    ;move mobs
    ifelse sleep-timer <= ticks [
      set color mob-color
      set label ""
      repeat [mob-speed] of self [
        ifelse any? heros-on neighbors and [smoke-screen-timer <= ticks] of patch-here and master = 0 [
          ;attack hero
          if random 10 + 1 > 4 and has-attacked? = false [ ;only 1 attack per tick, regardless of mob-speed
            battle self one-of heros 0 0
            set has-attacked? true
          ]
        ][
          ;move toward heros if they are close, otherwise move randomly
          ifelse (any? heros in-radius 7) and (random 10 + 1 > 3) and [smoke-screen-timer <= ticks] of patch-here [set heading towards one-of heros][set heading random 360]
          if (can-move? 1) and
          (not any? other mobs-on patch-ahead 1) and
          ([walkable? = true] of patch-ahead 1 or [magic-walk-thru-walls] of self = 1) and
          ([fireball-timer <= ticks] of patch-ahead 1) and
          [pycor < 15] of patch-ahead 1 [
            fd 1
          ]
        ]
        set xcor round xcor
        set ycor round ycor
        if [mob-speed] of self > 1 and [discovered? = true] of patch-here [wait 0.05]
      ]
    ][
      set color grey
      set label "zzzz"
    ]
  ]

  ;move the mobs under hero's command
  ask mobs with [master = one-of heros] [
    ;move mobs
    ifelse sleep-timer <= ticks [
      set color mob-color
      set label ""
      repeat [mob-speed] of self [
        ifelse any? (mobs-on neighbors) with [master = 0] and [smoke-screen-timer <= ticks] of patch-here [
          ;attack monsters
          ;only 1 attack per tick, regardless of mob-speed
          battle self one-of (mobs-on neighbors) with [master = 0] 0 0
          set has-attacked? true
        ][

          ;move toward heros if they are close, otherwise move randomly
          ifelse (any? heros in-radius 7) and
          not any? heros-here and
          (random 10 + 1 > 3) and
          [smoke-screen-timer <= ticks] of patch-here [
            set heading towards one-of heros
          ][
            set heading random 360
          ]

          ;move forward
          if (can-move? 1) and
          (not any? other mobs-on patch-ahead 1) and
          (not any? heros-on patch-ahead 1) and
          ([walkable? = true] of patch-ahead 1 or [magic-walk-thru-walls] of self = 1) and
          ([fireball-timer <= ticks] of patch-ahead 1) and
          [pycor < 15] of patch-ahead 1 [
            fd 1
          ]
        ]
        set xcor round xcor
        set ycor round ycor
        if [mob-speed] of self > 1 and [discovered? = true] of patch-here [wait 0.05]
      ]
    ][
      set color grey
      set label "zzzz"
    ]
  ]




end

to generate-tunnel-level [name]
  clear-patches
  clear-turtles

  let number-of-items 0 ;used for littering stuff in the caves


  ask patches with [pycor < 15] [
    set walkable? false
    set discovered? false
  ]

  ask patches with [pycor > 14] [set discovered? true]



  ;create the layout
  repeat 50 [
    ask one-of patches with [pycor < 15] [
      set walkable? true
      set tunnel-x pxcor
      set tunnel-y pycor
    ]
    repeat 15 [
      set direction random 4 + 1

      repeat random 5 [
        if direction = 1 [if tunnel-x > -16 [set tunnel-x tunnel-x - 1]]
        if direction = 2 [if tunnel-x < 16 [set tunnel-x tunnel-x + 1]]
        if direction = 3 [if tunnel-y > -16 [set tunnel-y tunnel-y - 1]]
        if direction = 4 [if tunnel-y < 16 [set tunnel-y tunnel-y + 1]]

        ask patch tunnel-x tunnel-y [
          set walkable? true
        ]
      ]
    ]

  ]

  ;create a trap door and boobytraps for levels 3+
  if name > 3 [
  repeat random level + 1 [
    ask one-of patches with [walkable? = true and pycor < 15] [
      set boobytrap? true
    ]
  ]
    ask one-of patches with [walkable? = true and pycor < 15] [
      set trap-door? true
    ]
  ]

  ;generate some monsters
  if name = 1 [generate-mob 5]
  if name >= 2 and name <= 10 [generate-mob random 10 + 5]
  if name > 10 [generate-mob random 15 + 5]


  ;generate bosses
  if name = 5 [generate-boss-mob]
  if name = 10 [generate-boss-mob]
  if name = 15 [generate-boss-mob]
  if name = 20 [generate-boss-mob]


  ;add in the exit and the hero
  ask one-of patches with [walkable? = true and pycor < 15] [
    set discovered? false
    sprout-buildings 1 [
      set shape "arrow"
      set heading 0
      setxy round xcor round ycor
      set building-type "upshaft"
      set color brown
    ]
  ]

  ;add in a spellbook
  ask one-of patches with [walkable? = true and pycor < 15] [
    sprout-spellbooks 1 [
      set spell-level name
      set shape "spellbook"
    ]
  ]

  ;add in some treasure chests
  set number-of-items random 5 + 1
  repeat number-of-items [
    ask one-of patches with [walkable? = true and pycor < 15] [
      sprout-treasure-chests 1 [
        set shape "treasure-chest"
        ifelse random 100 + 1 <= 20 [set trapped? true][set trapped? false]
      ]
    ]
  ]

  ;add a few random items
  set number-of-items random 1
  repeat number-of-items [
    ask one-of patches with [walkable? = true and pycor < 15] [
      set level name
      drop-item self level
    ]
  ]


  ;add a few torches
  set number-of-items random 5
  repeat number-of-items [
    ask one-of patches with [walkable? = true and pycor < 15] [
      sprout-torches 1 [
        set shape "torch"
        set torch-used 0
        set torch-timer random 75 + 1
      ]
    ]
  ]

  ;add the hole to the next level down
  if name != 20 [
    ask one-of patches with [walkable? = true and pycor < 15] [
      set discovered? false
      sprout-buildings 1 [
        set shape "arrow"
        set heading 180
        setxy round xcor round ycor
        set building-type "downshaft"
        set color brown
      ]
    ]
  ]

  ;for levels 8 and below, a 5% chance of generating a wolf pack
  if name >= 8 and random 100 + 1 >= 95 [generate-wolf-pack]

  save-level word "cave-" name
end

to shop-for-weapons
  let item-choice user-one-of "Which item are you interested in?" [
    "Nothing today, thank you."
    "[$100] Dagger - 4 damage"
    "[$750] Short Sword - 6 damage"
    "[$1500] Short Bow - 4 damage - 4 Range"
    "[$1500] Sword - 8 damage"
    "[$2500] Longsword - 10 damage"
    "[$3750] Pike - 12 damage"
    "[$5000] Broadsword - 14 damage"
    "[$6500] Scimitar - 15 damage"
    "[$7500] Battle Axe - 16 damage"
  ]

  if item-choice = "Nothing today, thank you." [print "You leave the store."]

  if item-choice = "[$100] Dagger - 4 damage" and [gold] of one-of heros >= 100 [
    print "You bought a dagger."
    ask one-of heros [set gold gold - 100]
    ask weapons with [weapon-type = "hand" and weapon-used = 1][die]
    create-weapons 1 [
      set shape "dagger"
      set color 6
      set weapon-type "hand"
      set weapon-name "dagger"
      set weapon-damage 4
      set weapon-cost 100
      set weapon-used 0
      setxy -9 5
    ]
  ]

  if item-choice = "[$750] Short Sword - 6 damage" and [gold] of one-of heros >= 750 [
    print "You bought a short sword."
    ask one-of heros [set gold gold - 750]
    ask weapons with [weapon-type = "hand" and weapon-used = 1][die]
    create-weapons 1 [
      set shape "dagger"
      set color 75
      set weapon-type "hand"
      set weapon-name "short sword"
      set weapon-damage 6
      set weapon-cost 175
      set weapon-used 0
      setxy -9 5
    ]
  ]


  if item-choice = "[$1500] Short Bow - 4 damage - 4 Range" and [gold] of one-of heros >= 1500 [
    print "You bought a short bow."
    ask one-of heros [set gold gold - 1500]
    ask weapons with [weapon-type = "ranged" and weapon-used = 1][die]
    create-weapons 1 [
      set shape "short-bow"
      set color 45
      set weapon-type "ranged"
      set weapon-name "short-bow"
      set weapon-damage 4
      set weapon-ammo random 10 + 2
      set weapon-cost 200
      set weapon-used 0
      setxy -9 5
    ]
  ]

  if item-choice = "[$1500] Sword - 8 damage" and [gold] of one-of heros >= 1500 [
    print "You bought a sword."
    ask one-of heros [set gold gold - 1500]
    ask weapons with [weapon-type = "hand" and weapon-used = 1][die]
    create-weapons 1 [
      set shape "dagger"
      set color 45
      set weapon-type "hand"
      set weapon-name "sword"
      set weapon-damage 8
      set weapon-cost 225
      set weapon-used 0
      setxy -9 5
    ]
  ]

  if item-choice = "[$2500] Longsword - 10 damage" and [gold] of one-of heros >= 2500 [
    print "You bought a longsword."
    ask one-of heros [set gold gold - 2500]
    ask weapons with [weapon-type = "hand" and weapon-used = 1][die]
    create-weapons 1 [
      set shape "dagger"
      set color 45
      set weapon-type "hand"
      set weapon-name "long sword"
      set weapon-damage 10
      set weapon-cost 250
      set weapon-used 0
      setxy -9 5
    ]
  ]

  if item-choice = "[$3750] Pike - 12 damage" and [gold] of one-of heros >= 3750 [
    print "You bought a pike."
    ask one-of heros [set gold gold - 3750]
    ask weapons with [weapon-type = "hand" and weapon-used = 1][die]
    create-weapons 1 [
      set shape "pike"
      set weapon-type "hand"
      set weapon-name "pike"
      set weapon-damage 12
      set weapon-cost 300
      set weapon-used 0
      setxy -9 5
    ]
  ]

  if item-choice = "[$5000] Broadsword - 14 damage" and [gold] of one-of heros >= 5000 [
    print "You bought a broadsword."
    ask one-of heros [set gold gold - 5000]
    ask weapons with [weapon-type = "hand" and weapon-used = 1][die]
    create-weapons 1 [
      set shape "broadsword"
      set weapon-type "hand"
      set weapon-name "broadsword"
      set weapon-damage 14
      set weapon-cost 400
      set weapon-used 0
      setxy -9 5
    ]
  ]

  if item-choice = "[$6500] Scimitar - 15 damage" and [gold] of one-of heros >= 6500 [
    print "You bought a scimitar."
    ask one-of heros [set gold gold - 6500]
    ask weapons with [weapon-type = "hand" and weapon-used = 1][die]
    create-weapons 1 [
      set shape "scimitar"
      set weapon-type "hand"
      set weapon-name "scimitar"
      set weapon-damage 15
      set weapon-cost 750
      set weapon-used 0
      setxy -9 5
    ]
  ]

  if item-choice = "[$7500] Battle Axe - 16 damage" and [gold] of one-of heros >= 7500 [
    print "You bought a battle axe."
    ask one-of heros [set gold gold - 7500]
    ask weapons with [weapon-type = "hand" and weapon-used = 1][die]
    create-weapons 1 [
      set shape "battle-axe"
      set weapon-type "hand"
      set weapon-name "battle axe"
      set weapon-damage 16
      set weapon-cost 850
      set weapon-used 0
      setxy -9 5
    ]
  ]



  ;reset the whats-here
  set whats-here ""
end

to shop-for-armor

  let armor-choice user-one-of "Which suit of armor are you interested in?" [
    "Nothing today, thank you."
    "[$150] Leather Armor - Armor Value 10"
    "[$2500] Chainmail Armor - Armor Value 35"
  ]

  if armor-choice = "Nothing today, thank you." [print "You leave the hardware store."]

  if armor-choice = "[$150] Leather Armor - Armor Value 10" and [gold] of one-of heros >= 150 [
    print "You bought a suit of leather armor."
    ask one-of heros [set gold gold - 150]
    create-armors 1 [
      set shape "leather-armor"
      set armor-name "leather armor"
      set color white
      set armor-value 10
      set armor-cost 10
      set armor-used 0
      setxy -5 5
    ]
  ]

  if armor-choice = "[$2500] Chainmail Armor - Armor Value 35" and [gold] of one-of heros >= 2500 [
    print "You bought a suit of chainmail armor."
    ask one-of heros [set gold gold - 2500]
    create-armors 1 [
      set shape "chain-armor"
      set armor-name "chainmail armor"
      set color blue
      set armor-value 20
      set armor-cost 35
      set armor-used 0
      setxy -5 5
    ]
  ]

  ;reset whats-here
  set whats-here ""

end

to shop-for-hardware

  let hardware-choice user-one-of "Which item are you interested in?" [
    "Nothing today, thank you."
    "[$100] Torch - 100 turns of light"
    "[$250] Torch - 250 turns of light"
    "[$500] Torch - 500 turns of light"
    "[$1000] Torch - 1000 turns of light"
  ]

  if hardware-choice = "Nothing today, thank you." [print "You leave the hardware store."]

  if hardware-choice = "[$100] Torch - 100 turns of light" and [gold] of one-of heros >= 100 [
    print "You bought a torch with 100 turns of light."
    ask one-of heros [set gold gold - 100]
    create-torches 1 [
      setxy -1 5
      set shape "torch"
      set color 45
      set torch-timer 100
      set torch-used 0
    ]
  ]

  if hardware-choice = "[$250] Torch - 250 turns of light" and [gold] of one-of heros >= 250 [
    print "You bought a torch with 250 turns of light."
    ask one-of heros [set gold gold - 250]
    create-torches 1 [
      setxy -1 5
      set shape "torch"
      set color 45
      set torch-timer 250
      set torch-used 0
    ]
  ]

  if hardware-choice = "[$500] Torch - 500 turns of light" and [gold] of one-of heros >= 500 [
    print "You bought a torch with 500 turns of light."
    ask one-of heros [set gold gold - 500]
    create-torches 1 [
      setxy -1 5
      set shape "torch"
      set color 45
      set torch-timer 500
      set torch-used 0
    ]
  ]

   if hardware-choice = "[$1000] Torch - 1000 turns of light" and [gold] of one-of heros >= 1000 [
    print "You bought a torch with 1000 turns of light."
    ask one-of heros [set gold gold - 1000]
    create-torches 1 [
      setxy -1 5
      set shape "torch"
      set color 45
      set torch-timer 1000
      set torch-used 0
    ]
  ]

  ;reset whats-here
  set whats-here ""


end

to shop-for-spells
  ifelse user-yes-or-no? "Would you like to buy a spellbook for $2500?" and [gold >= 2500] of one-of heros [
    create-spellbooks 1 [
      set shape "spellbook"
      set spell-level level
      setxy 0 -3
      ]
    ask one-of heros [set gold gold - 2500]
  ][print "You leave the school."]

  set whats-here ""

end

to generate-surface-level
  clear-patches
  clear-turtles

  ask patches with [pycor < 15] [set walkable? true]

  create-buildings 1 [
    set shape "house"
    setxy -9 4
    set building-type "weapons store"
    set label "weapons store"
    set color green
    if any? other buildings-here [fd 3]
  ]

  create-buildings 1 [
    set shape "house"
    setxy -5 4
    set building-type "armor store"
    set label "armor store"
    set color green
    if any? other buildings-here [fd 3]
  ]

  create-buildings 1 [
    set shape "house"
    setxy -1 4
    set building-type "hardware store"
    set label "hardware store"
    set color green
    if any? other buildings-here [fd 3]
  ]


  create-buildings 1 [
    set shape "house"
    setxy -9 -3
    set building-type "gym"
    set label "gym"
    set color red
    if any? other buildings-here [fd 3]
  ]

  create-buildings 1 [
    set shape "house"
    setxy -1 -3
    set building-type "school"
    set label "school"
    set color orange
    if any? other buildings-here [fd 3]
  ]

  create-buildings 1 [
    set shape "house"
    setxy -5 -3
    set building-type "coliseum"
    set label "coliseum"
    set color magenta
    if any? other buildings-here [fd 3]
  ]

  create-buildings 1 [
    set shape "triangle"
    setxy round random-xcor round random-ycor
    set building-type "cave"
    set color brown
    set size 2
    if any? other buildings-here [fd 3]
  ]

  ask buildings [
    if ycor > 14 [set ycor 14]
  ]

  ;start with a first spell
  create-spellbooks 1 [
    set shape "spellbook"
    set spell-level 1
    if ycor > 14 [set ycor 14]
  ]


end

to check-whats-here

  let temp-level level

  ask heros [
    ask buildings-here [set whats-here building-type]
    if not any? buildings-here [
      ask patch-here [
        if boobytrap? = true [
          set whats-here "boobytrap"
          set boobytrap? false
        ]
        if trap-door? = true [
          set whats-here "trap-door"
          set trap-door? false
        ]
      ]
    ]
  ]

  if whats-here = "weapons store" [shop-for-weapons]
  if whats-here = "armor store" [shop-for-armor]
  if whats-here = "hardware store" [shop-for-hardware]
  if whats-here = "school" [shop-for-spells]

  if whats-here = "cave" [
    save-level "surface"
    load-level "cave-1" whats-here
    set level 1
    set whats-here ""

  ]

  if whats-here = "upshaft" and level = 1 [
    save-level "cave-1"
    set level "surface"
    load-level "surface" whats-here
    set whats-here ""
  ]


  if whats-here = "upshaft" and level > 1 [
    save-level (word "cave-" level)
    set level temp-level - 1
    set temp-level temp-level - 1

    load-level (word "cave-" level) whats-here

    set level temp-level

    set whats-here ""
  ]

  if whats-here = "downshaft" [
    save-level (word "cave-" level)

    set level temp-level + 1
    set temp-level temp-level + 1

    load-level (word "cave-" level) whats-here

    set level temp-level

    set whats-here ""
  ]

  if whats-here = "trap-door" [

    user-message "You have fallen through a trap door!"

    save-level (word "cave-" level)

    set level temp-level + 1
    set temp-level temp-level + 1

    load-level (word "cave-" level) whats-here

    set level temp-level

    set whats-here ""
  ]

  ;spring a boobytrap
  if whats-here = "boobytrap" [
    print "You accidentally sprung a boobytrap!"
    if random 100 + 1 > 50 [
      ask heros [
        let booby-damage random 8 + 1
        set hp hp - booby-damage
        set size 5
        set label booby-damage
        wait 0.2
        set size 1
        set label ""
        ask patch-here [set boobytrap? false]
      ]
      check-for-death
    ]
    set whats-here ""
  ]



  ;pickup any treasures
  ask heros [
    ;pickup gold
    set gold gold + sum [coins] of treasures-here
    if any? treasures-here [print (word "You picked up " sum [coins] of treasures-here " gold.")]
    ask treasures-here [die]

    ;pickup weapons
    if any? weapons-here with [weapon-used = 0] [
      if user-yes-or-no? (word "Pickup " [weapon-name] of one-of weapons-here with [weapon-used = 0] "?") [
        print (word "You picked up a " [weapon-name] of one-of weapons-here with [weapon-used = 0] ".")

        ask weapons-here with [weapon-type = "hand" and weapon-used = 0] [
          ask weapons-here with [weapon-type = "hand" and weapon-used = 1] [set weapon-used 0] ;remove currently slotted weapon
          ask one-of heros [
            set in-hand [weapon-name] of myself
            set damage [weapon-damage] of myself
          ]
          set weapon-used 1
        ]


        ifelse count weapons-here with [weapon-type = "ranged"] > 1 [ ;if there is more than 1 bow
          ask one-of weapons with [weapon-type = "ranged" and weapon-used = 1] [
            set weapon-ammo weapon-ammo + random 23 + 1
          ]
          ask weapons-here with [weapon-type = "ranged" and weapon-used = 0] [die]
        ] [; if there is just 1 bow, pick it up
          ask weapons-here with [weapon-type = "ranged"] [
            set weapon-used 1
            set weapon-ammo weapon-ammo + random 23 + 1
            ask one-of heros [set ranged-weapon [weapon-name] of myself]
          ]
        ]


      ]
    ]


    ;pickup projectiles
    if any? projectiles-here with [color = yellow] [
      let picked-up-projectiles random 24 + 1
      ask weapons with [weapon-type = "ranged" and weapon-used = 1] [
        set weapon-ammo weapon-ammo + picked-up-projectiles
        print (word "You found " picked-up-projectiles " arrows.")
      ]

      ask projectiles-here [die]

    ]

    ;pickup armor
    if any? armors-here with [armor-used = 0] [
      if user-yes-or-no? (word "Pickup " [armor-name] of one-of armors-here with [armor-used = 0] "?") [
        print (word "You picked up some " [armor-name] of one-of armors-here with [armor-used = 0] ".")
        set armor-name [armor-name] of one-of armors-here with [armor-used = 0]
        set armor-value [armor-value] of one-of armors-here with [armor-used = 0]
        ask armors-here with [armor-used = 1] [set armor-used 0] ;remove currently used armor
        ask armors-here with [armor-used = 0] [set armor-used 1]
      ]
    ]

    ;pickup torches
    if any? torches-here with [torch-used = 0] [
        print (word "You picked up a torch.")
        ifelse any? torches-here with [torch-used = 1] [ ;if you are currently holding a torch, do this
          ask torches-here with [torch-used = 0] [die]
          ask torches-here with [torch-used = 1] [
            set torch-timer torch-timer + random 75 + 1
          ]
        ] [;if you don't have a torch, do this
          ask torches-here with [torch-used = 0] [set torch-used 1]
        ]
    ]

    ;open chests
    if any? treasure-chests-here [
      print "You attempt to open the chest. . ."

      ;some cool "opening chest" graphics
      ask treasure-chests-here [
        repeat random 5 + 1 [
          set size 2
          wait 0.2
          set size 1
          wait 0.1
        ]

        ;check for traps
        if trapped? = true [
          user-message "The chest was trapped!"
          ask one-of heros [
            let trap-damage random (level * 8) + 1
            set hp hp - trap-damage
            if hp <= 0 [set hp 1]
            set size 5
            set label trap-damage
            wait 0.2
            set size 1
            set label ""
          ]
        ]
      ]
      check-for-death

      ;now open it
      print "You found treasure in the chest!"
      ask neighbors with [walkable? = true] [
        let drop-chance random 100 + 1 ; the chances of dropping various items
        if drop-chance >= 0 and drop-chance <= 50 [
          sprout-treasures 1 [
            set coins random (level * 100) + 1
            set color 45
            set shape "coin"
          ]
        ]

        if drop-chance >= 51 and drop-chance <= 75 [
          drop-item self level
        ]
      ]

      ;now remove chest
      ask treasure-chests-here [die]
    ]

    pickup-spellbook

  ]

  wear-gear


end

to pickup-spellbook

  let spell-chance 0

  if any? spellbooks-here [
    print (word "You picked up a spellbook.")

    ask one-of heros [
      if xp-level <= 2 [set spell-chance random 3 + 1] ;level 1 spells
      if xp-level >= 3 and xp-level <= 4 [set spell-chance random 6 + 1] ; level 2 spells
      if xp-level >= 5 and xp-level <= 6 [set spell-chance random 9 + 1] ; level 3 spells
      if xp-level >= 7 and xp-level <= 8 [set spell-chance random 12 + 1] ; level 4 spells
      if xp-level >= 9  and xp-level <= 10 [set spell-chance random 15 + 1] ;level 5 spells
      if xp-level >= 11 and xp-level <= 12 [set spell-chance random 18 + 1] ;level 6 spells
      if xp-level >= 13 [set spell-chance random 21 + 1] ;level 7 spells

    ]

    ;level 1 spells
    if spell-chance = 1 [
      ifelse spell-magic-missile = 0 [
        set spell-magic-missile 1
        print "You learned the new spell -- Magic Missile !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 2 [
      ifelse spell-sense-danger = 0 [
        set spell-sense-danger 1
        print "You learned the new spell - Sense Danger !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 3 [
      ifelse spell-light = 0 [
        set spell-light 1
        print "You learned the new spell -- Light !"
      ][print "You found nothing useful in the spellbook"]
    ]


    ;level 2 spells
    if spell-chance = 4 [
      ifelse spell-flame-tongue = 0 [
        set spell-flame-tongue 1
        print "You learned the new spell -- Flame Tongue !"
      ][print "You found nothing useful in the spellbook"]
    ]


    if spell-chance = 5 [
      ifelse spell-heal = 0 [
        set spell-heal 1
        print "You learned the new spell -- Heal !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 6 [
      ifelse spell-smoke-screen = 0 [
        set spell-smoke-screen 1
        print "You learned the new spell - Smoke Screen !"
      ][print "You found nothing useful in the spellbook"]
    ]


    ;level 3 spells
    if spell-chance = 7 [
      ifelse spell-enlightenment = 0 [
        set spell-enlightenment 1
        print "You learned the new spell - Enlightenment !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 8 [
      ifelse spell-strength = 0 [
        set spell-strength 1
        print "You learned the new spell - Strength !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 9 [
      ifelse spell-protection = 0 [
        set spell-protection 1
        print "You learned the new spell - Protection !"
      ][print "You found nothing useful in the spellbook"]
    ]


    ;level 4 spells
    if spell-chance = 10 [
      ifelse spell-lightning-bolt = 0 [
        set spell-lightning-bolt 1
        print "You learned the new spell - Lightning Bolt !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 11 [
      ifelse spell-magic-fire = 0 [
        set spell-magic-fire 1
        print "You learned the new spell - Magic Fire !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 12 [
      ifelse spell-dexterity = 0 [
        set spell-dexterity 1
        print "You learned the new spell - Dexterity !"
      ][print "You found nothing useful in the spellbook"]
    ]

    ;level 5 spells
    if spell-chance = 13 [
      ifelse spell-sanctuary = 0 [
        set spell-sanctuary 1
        print "You learned the new spell - Sanctuary !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 14 [
      ifelse spell-drain-life = 0 [
        set spell-drain-life 1
        print "You learned the new spell - Drain Life !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 15 [
      ifelse spell-walk-through-walls = 0 [
        set spell-walk-through-walls 1
        print "You learned the new spell - Walk Through Walls !"
      ][print "You found nothing useful in the spellbook"]
    ]

    ;level 6 spells
    if spell-chance = 16 [
      ifelse spell-fireball = 0 [
        set spell-fireball 1
        print "You learned the new spell - Fireball !"
      ][print "You found nothing useful in the spellbook"]
    ]


    if spell-chance = 17 [
      ifelse spell-sleep = 0 [
        set spell-sleep 1
        print "You learned the new spell - Sleep !"
      ][print "You found nothing useful in the spellbook"]
    ]


    if spell-chance = 18 [
      ifelse spell-teleport = 0 [
        set spell-teleport 1
        print "You learned the new spell - Teleport !"
      ][print "You found nothing useful in the spellbook"]
    ]

    ;level 7 spells
    if spell-chance = 19 [
      ifelse spell-sphere-of-annihilation = 0 [
        set spell-sphere-of-annihilation 1
        print "You learned the new spell - Sphere of Annihilation !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 20 [
      ifelse spell-animate-dead = 0 [
        set spell-animate-dead 1
        print "You learned the new spell - Animate Dead !"
      ][print "You found nothing useful in the spellbook"]
    ]

    if spell-chance = 21 [
      ifelse spell-create-item = 0 [
        set spell-create-item 1
        print "You learned the new spell - Create Item !"
      ][print "You found nothing useful in the spellbook"]
    ]

    ask spellbooks-here [die]
  ]
end

to drop-item [patch-location item-level]
  let item-chance 0

  if item-level = 1 [set item-chance random 7 + 1] ; a random number to determine which item gets dropped
  if item-level = 2 [set item-chance random 10 + 1]
  if item-level = 3 [set item-chance random 13 + 1]
  if item-level >= 4 [set item-chance random 14 + 1]

  ask patch-location [
    if item-chance = 1 [
      sprout-weapons 1 [
        set shape "dagger"
          set color 6
          set weapon-type "hand"
          set weapon-name "dagger"
          set weapon-damage 4
          set weapon-cost 100
          set weapon-used 0
        ]
      ]

      if item-chance = 2 [
        sprout-weapons 1 [
          set shape "dagger"
          set color 75
          set weapon-type "hand"
          set weapon-name "short sword"
          set weapon-damage 6
          set weapon-cost 175
          set weapon-used 0
        ]
      ]

    if item-chance = 3 [
      sprout-armors 1 [
        set shape "leather-armor"
        set armor-name "leather armor"
        set color white
        set armor-value 10
        set armor-cost 10
        set armor-used 0
      ]
    ]

    if item-chance = 4 [
      sprout-weapons 1 [
        set shape "short-bow"
        set color 45
        set weapon-type "ranged"
        set weapon-name "short-bow"
        set weapon-damage 4
        set weapon-ammo random 10 + 2
        set weapon-cost 200
        set weapon-used 0
      ]
    ]

    if item-chance = 5 [
      sprout-projectiles 1 [
        set shape "projectile"
        set color 45
      ]
    ]

    if item-chance = 6 [
      sprout-spellbooks 1 [
        set shape "spellbook"
        set spell-level level
      ]
    ]

    if item-chance = 7 [
      sprout-torches 1 [
        set shape "torch"
        set color 45
        set torch-timer random 100 + 10
        set torch-used 0
      ]
    ]

    if item-chance = 8 [
      sprout-weapons 1 [
        set shape "dagger"
        set color 45
        set weapon-type "hand"
        set weapon-name "sword"
        set weapon-damage 8
        set weapon-cost 225
        set weapon-used 0
      ]
    ]

    if item-chance = 9 [
      sprout-armors 1 [
        set shape "chain-armor"
        set armor-name "chainmail armor"
        set color blue
        set armor-value 20
        set armor-cost 35
        set armor-used 0
      ]
    ]

    if item-chance = 10 [
      sprout-weapons 1 [
        set shape "dagger"
        set color 45
        set weapon-type "hand"
        set weapon-name "long sword"
        set weapon-damage 10
        set weapon-cost 250
        set weapon-used 0
      ]
    ]

    if item-chance = 11 [
      sprout-weapons 1 [
        set shape "pike"
        set weapon-type "hand"
        set weapon-name "pike"
        set weapon-damage 12
        set weapon-cost 300
        set weapon-used 0
      ]
    ]

    if item-chance = 12 [
      sprout-weapons 1 [
        set shape "broadsword"
        set weapon-type "hand"
        set weapon-name "broadsword"
        set weapon-damage 14
        set weapon-cost 400
        set weapon-used 0
      ]
    ]

    if item-chance = 13 [
      sprout-weapons 1 [
        set shape "scimitar"
        set weapon-type "hand"
        set weapon-name "scimitar"
        set weapon-damage 15
        set weapon-cost 250
        set weapon-used 0
      ]
    ]

    if item-chance = 14 [
      sprout-weapons 1 [
        set shape "battle-axe"
        set weapon-type "hand"
        set weapon-name "battle axe"
        set weapon-damage 16
        set weapon-cost 850
        set weapon-used 0
      ]
    ]
  ]

end

to fire-ranged-weapon [ranged-weapon-direction]

  ;check for ammo
  if any? weapons with [weapon-type = "ranged" and weapon-used = 1 and weapon-ammo < 1] [print ("You are out of ammo!")]

  ;check for smoke-screen
  ask one-of heros [
    ifelse [smoke-screen-timer > ticks] of patch-here [
      print "It's too smokey to shoot your bow!"
    ][
      ;fire!
      if any? weapons-here with [weapon-type = "ranged" and weapon-used = 1 and weapon-ammo > 0] [
        hatch-projectiles 1 [
          set shape "arrow2"
          set color brown
          set projectile-damage [weapon-damage] of one-of weapons with [weapon-type = "ranged" and weapon-used = 1]
          print (word "A project with max-damage of " projectile-damage " has been fired.")
          if ranged-weapon-direction = "w" [set heading 0]
          if ranged-weapon-direction = "d" [set heading 90]
          if ranged-weapon-direction = "x" [set heading 180]
          if ranged-weapon-direction = "a" [set heading 270]
          if count mobs > 0 [if ranged-weapon-direction = "s" [set heading towards min-one-of mobs [distance myself]]]
        ]

        ;use up 1 ammo
        ask one-of weapons with [weapon-type = "ranged" and weapon-used = 1] [set weapon-ammo weapon-ammo - 1]

        ;move projectile and attack roll
        ask one-of projectiles with [color = brown] [
          repeat 4 [
            ifelse any? mobs-on patch-ahead 1 and [walkable? = true] of patch-ahead 1 [
              battle self one-of mobs-on patch-ahead 1 0 0
            ][
              ifelse [walkable? = true] of patch-ahead 1 [fd 1][die]
            ]
            wait 0.05
          ]
          die
        ]
      ]
    ]
  ]

  ;take a turn
  move "rest"
end
@#$#@#$#@
GRAPHICS-WINDOW
3
10
671
679
-1
-1
20.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
682
21
746
54
Reset
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
833
111
896
144
N
move \"north\"
NIL
1
T
OBSERVER
NIL
8
NIL
NIL
1

BUTTON
832
176
896
209
S
move \"south\"
NIL
1
T
OBSERVER
NIL
2
NIL
NIL
1

BUTTON
769
143
833
176
W
move \"west\"
NIL
1
T
OBSERVER
NIL
4
NIL
NIL
1

BUTTON
896
143
959
176
E
move \"east\"
NIL
1
T
OBSERVER
NIL
6
NIL
NIL
1

BUTTON
896
110
959
143
NE
move \"north-east\"
NIL
1
T
OBSERVER
NIL
9
NIL
NIL
1

BUTTON
896
176
959
209
SE
move \"south-east\"
NIL
1
T
OBSERVER
NIL
3
NIL
NIL
1

BUTTON
769
176
832
209
SW
move \"south-west\"
NIL
1
T
OBSERVER
NIL
1
NIL
NIL
1

BUTTON
770
111
833
144
NW
move \"north-west\"
NIL
1
T
OBSERVER
NIL
7
NIL
NIL
1

BUTTON
833
143
896
176
Rest
move \"rest\"
NIL
1
T
OBSERVER
NIL
5
NIL
NIL
1

MONITOR
967
39
1044
96
HP
(word [hp] of one-of heros \"/\" [max-hp] of one-of heros)
0
1
14

MONITOR
817
35
914
92
Cave Depth
level
0
1
14

MONITOR
968
176
1072
233
In Hand
[in-hand] of one-of heros
0
1
14

MONITOR
967
115
1090
172
Wearing
[armor-name] of one-of heros
0
1
14

MONITOR
1119
39
1176
96
XP
[xp] of one-of heros
0
1
14

MONITOR
1242
39
1309
96
Gold
[gold] of one-of heros
0
1
14

MONITOR
1181
39
1238
96
Level
[xp-level] of one-of heros
0
1
14

BUTTON
445
716
550
749
Cheat Button
ask heros [\nset hp 250\nset max-hp 250\nset damage 200\nset max-mana 100\nset mana 100\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1072
176
1144
233
Damage
[damage] of one-of heros
0
1
14

MONITOR
1090
115
1180
172
Armor Value
[armor-value] of one-of heros
0
1
14

BUTTON
769
326
832
359
W
fire-ranged-weapon \"w\"
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
831
359
894
392
D
fire-ranged-weapon \"d\"
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
705
359
768
392
A
fire-ranged-weapon \"a\"
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
769
392
832
425
X
fire-ranged-weapon \"x\"
NIL
1
T
OBSERVER
NIL
X
NIL
NIL
1

MONITOR
1173
237
1232
294
Ammo
[weapon-ammo] of one-of weapons with [weapon-type = \"ranged\" and weapon-used = 1]
0
1
14

MONITOR
969
237
1101
294
Ranged Weapon
[weapon-name] of one-of weapons with [weapon-type = \"ranged\" and weapon-used = 1]
0
1
14

MONITOR
1101
237
1173
294
Damage
[weapon-damage] of one-of weapons with [weapon-type = \"ranged\" and weapon-used = 1]
0
1
14

BUTTON
775
496
838
529
Cast
cast-spell
NIL
1
T
OBSERVER
NIL
C
NIL
NIL
1

MONITOR
1054
39
1111
96
Mana
(word [mana] of one-of heros \"/\" [max-mana] of one-of heros)
0
1
14

OUTPUT
1311
18
1632
354
14

BUTTON
448
755
618
788
Cheat - Show Everything
ask patches [set discovered? true]\nupdate-display
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
768
359
832
392
Shoot
fire-ranged-weapon \"s\"
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
696
647
786
680
downshaft
ask one-of patches with [walkable? = true and pycor < 15] [\n      set discovered? false\n      sprout-buildings 1 [\n        set shape \"arrow\"\n        set heading 180\n        setxy round xcor round ycor\n        set building-type \"downshaft\"\n        set color brown\n      ]\n    ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
997
336
1069
393
Level XP
sum [xp] of mobs
0
1
14

BUTTON
976
497
1063
530
make mob
let this-level level\nif level = \"surface\" [set this-level 1]\n\ncreate-mobs 1 [\n          set mob-name \"ghast\"\n          set hp 0\n          repeat this-level [set hp hp + random 18 + 1]\n          set max-hp hp\n          set heal-rate 1\n          set armor-value random 35 + 1\n          set shape \"ghast\"\n          set damage 0\n          repeat this-level [set damage damage + random 4 + 1]\n          set mob-speed 1\n          set magic-walk-thru-walls 1\n          set xp ((hp + armor-value) * damage)\n        ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
979
545
1121
578
Build House [$2500]
build-house
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

arrow2
true
0
Polygon -7500403 true true 135 255 105 300 105 225 135 195 135 75 105 90 150 0 195 90 165 75 165 195 195 225 195 300 165 255

battle-axe
true
0
Polygon -7500403 true true 45 45 60 180 165 120 255 165 255 45 150 75 45 45
Polygon -6459832 true false 135 120 150 285 165 270 165 120 150 105

boss
false
0
Circle -7500403 true true 105 0 90
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 210 75 240 150 225 180 165 105
Polygon -7500403 true true 90 75 60 150 75 180 135 105
Polygon -7500403 true true 120 195 90 240 90 285
Polygon -7500403 true true 210 285 210 225 180 195
Polygon -7500403 true true 60 150 30 165 30 210 45 165 45 210 60 180 60 225 75 180
Polygon -7500403 true true 240 150 270 165 270 210 255 180 255 210 240 180 240 225 225 180
Polygon -16777216 true false 180 60 165 45 135 45 120 60 135 60 150 60
Polygon -2674135 true false 120 15 150 30 135 30
Polygon -2674135 true false 150 30 180 15 165 30
Line -16777216 false 180 0 150 15
Line -16777216 false 150 15 120 0

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

broadsword
true
0
Polygon -7500403 true true 150 0 135 45 135 195 90 195 90 210 135 210 135 255 165 255 165 210 210 210 210 195 165 195 165 45
Polygon -6459832 true false 135 210 165 210 165 255 135 255

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

caterpillar
true
0
Polygon -7500403 true true 165 210 165 225 135 255 105 270 90 270 75 255 75 240 90 210 120 195 135 165 165 135 165 105 150 75 150 60 135 60 120 45 120 30 135 15 150 15 180 30 180 45 195 45 210 60 225 105 225 135 210 150 210 165 195 195 180 210
Line -16777216 false 135 255 90 210
Line -16777216 false 165 225 120 195
Line -16777216 false 135 165 180 210
Line -16777216 false 150 150 201 186
Line -16777216 false 165 135 210 150
Line -16777216 false 165 120 225 120
Line -16777216 false 165 106 221 90
Line -16777216 false 157 91 210 60
Line -16777216 false 150 60 180 45
Line -16777216 false 120 30 96 26
Line -16777216 false 124 0 135 15
Polygon -2674135 true false 135 15 150 30 150 15
Polygon -2674135 true false 120 30 135 45 135 30

cave bat
false
0
Polygon -7500403 true true 135 165 90 285 120 300 180 300 210 285 165 165
Rectangle -7500403 true true 120 105 180 237
Polygon -7500403 true true 135 105 120 75 105 45 121 6 167 8 207 25 257 46 180 75 165 105
Polygon -2674135 true false 150 15 180 45 150 45
Polygon -7500403 true true 180 105 255 75 300 150 285 195 285 150 240 135 180 195
Polygon -7500403 true true 120 105 60 75 0 150 45 195 30 150 60 135 120 195

chain-armor
false
0
Polygon -13345367 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -16777216 true false 123 90 149 141 177 90
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -13345367 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -13345367 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Rectangle -16777216 true false 118 129 141 140

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

coin
false
0
Circle -7500403 true true 15 15 270
Circle -16777216 false false 22 21 256
Line -16777216 false 165 180 192 196
Line -16777216 false 42 140 83 140
Line -16777216 false 37 151 91 151
Line -16777216 false 218 167 265 167
Polygon -16777216 false false 148 265 75 229 86 207 113 191 120 175 109 162 109 136 86 124 137 96 176 93 210 108 222 125 203 157 204 174 190 191 232 230
Polygon -16777216 false false 212 142 182 128 154 132 140 152 149 162 144 182 167 204 187 206 193 193 190 189 202 174 193 158 202 175 204 158
Line -16777216 false 164 154 182 152
Line -16777216 false 193 152 202 153
Polygon -16777216 false false 60 75 75 90 90 75 105 75 90 45 105 45 120 60 135 60 135 45 120 45 105 45 135 30 165 30 195 45 210 60 225 75 240 75 225 75 210 90 225 75 225 60 210 60 195 75 210 60 195 45 180 45 180 60 180 45 165 60 150 60 150 45 165 45 150 45 150 30 135 30 120 60 105 75

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dagger
true
0
Polygon -7500403 true true 165 0 165 15 180 150 195 165 195 180 180 195 165 225 135 225 120 195 105 180 105 165 120 150 135 15 135 0
Line -16777216 false 120 150 180 150
Line -16777216 false 120 195 180 195
Line -16777216 false 165 15 135 15
Polygon -16777216 false false 165 0 135 0 135 15 120 150 105 165 105 180 120 195 135 225 165 225 180 195 195 180 195 165 180 150 165 15

dire wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113
Circle -2674135 true false 255 105 0
Polygon -2674135 true false 255 105 255 120 270 120 255 105

dot
false
0
Circle -7500403 true true 90 90 120

drop
false
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

ghast
false
0
Polygon -7500403 true true 30 165 13 164 -2 149 0 135 -2 119 0 105 15 75 30 75 58 104 43 119 43 134 58 134 73 134 88 104 73 44 78 14 103 -1 193 -1 223 29 208 89 208 119 238 134 253 119 240 105 238 89 240 75 255 60 270 60 283 74 300 90 298 104 298 119 300 135 285 135 285 150 268 164 238 179 208 164 208 194 238 209 253 224 268 239 268 269 238 299 178 299 148 284 103 269 58 284 43 299 58 269 103 254 148 254 193 254 163 239 118 209 88 179 73 179 58 164
Line -16777216 false 189 253 215 253
Circle -2674135 true false 102 30 30
Polygon -16777216 true false 165 105 135 105 120 120 105 105 135 75 165 75 195 105 180 120
Circle -2674135 true false 160 30 30

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

leather-armor
false
0
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -6459832 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -6459832 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Rectangle -16777216 true false 118 129 141 140

lightning
true
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

pike
true
0
Line -7500403 true 150 0 150 300
Polygon -7500403 true true 150 0 135 45 165 45

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

projectile
true
0
Polygon -7500403 true true 135 255 105 300 105 225 135 195 135 75 105 90 150 0 195 90 165 75 165 195 195 225 195 300 165 255

scimitar
true
0
Polygon -7500403 true true 150 0 105 45 135 195 90 195 90 225 135 210 135 255 165 255 165 210 210 225 210 195 165 195 165 45
Polygon -6459832 true false 135 210 165 210 165 255 135 255

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

short-bow
true
0
Line -7500403 true 165 75 165 75
Polygon -7500403 true true 240 150 90 195
Polygon -7500403 true true 225 180
Polygon -7500403 true true 150 45 225 135 225 165 150 255 150 270 255 165 255 120 150 30
Line -7500403 true 165 60 165 240

spellbook
false
0
Polygon -7500403 true true 30 195 150 255 270 135 150 75
Polygon -7500403 true true 30 135 150 195 270 75 150 15
Polygon -7500403 true true 30 135 30 195 90 150
Polygon -1 true false 39 139 39 184 151 239 156 199
Polygon -1 true false 151 239 254 135 254 90 151 197
Line -7500403 true 150 196 150 247
Line -7500403 true 43 159 138 207
Line -7500403 true 43 174 138 222
Line -7500403 true 153 206 248 113
Line -7500403 true 153 221 248 128
Polygon -1 true false 159 52 144 67 204 97 219 82

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

torch
true
0
Polygon -1 true false 87 191 103 218 238 53 223 38
Polygon -13345367 true false 104 204 104 218 239 53 235 47
Polygon -7500403 true true 99 173 83 175 71 186 64 207 52 235 45 251 77 238 108 227 124 205 118 185

treasure-chest
false
0
Rectangle -7500403 true true 45 45 255 255
Rectangle -16777216 false false 45 45 255 255
Rectangle -16777216 false false 60 60 240 240
Line -16777216 false 180 60 180 240
Line -16777216 false 150 60 150 240
Line -16777216 false 120 60 120 240
Line -16777216 false 210 60 210 240
Line -16777216 false 90 60 90 240
Polygon -7500403 true true 75 240 240 75 240 60 225 60 60 225 60 240
Polygon -16777216 false false 60 225 60 240 75 240 240 75 240 60 225 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
