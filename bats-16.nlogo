globals
[
  ;; bat variables
  how-many-bats-to-start
  percent-infected-to-start
  average-lifespan
  average-infection-to-death-time
  average-recovery-time
  average-fungal-threshold
  birth-probability
  adult-death-probability
  baby-death-probability
  immune-after-recovery?
  susceptible-bat-color
  infected-bat-color
  dead-bat-color
  immune-bat-color
  how-many-bats
  flash-time
  adult-size
  baby-size
  adult-age


  ;; seasonal variables
  cycle-length
  transition-length
  spring-start
  summer-start
  autumn-start
  winter-start
  tmod
  season
  winter-color
  summer-color
  season-color-scale

  ;; cave variables
  fungal-patch-size
  fungal-patches
  cave-size
  cave-color
  contaminated-color

  ;; model variables
  allow-birth?
  allow-natural-death?
]


turtles-own
[
  infected?
  cured?
  immune?
  susceptible?
  contagious?
  dead?
  recovery-time
  infection-to-death-time
  fungal-threshold
  max-fungal-load
  fungal-reduce-probability
  has-been-infected?
  infection-length
  recovery-length
  lifespan
  age
  sex
  fungal-load
  flashing?
  flash-length
  adult?
  given-birth-this-year?
]


patches-own
[
  contaminated?
  cave?
  border?
  cave-border?
]


;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  set allow-birth? false
  set allow-natural-death? false

  set cycle-length 365
  set summer-color 93
  set winter-color black
  set season-color-scale [12 17 25 27]

  set transition-length cycle-length / 10
  set spring-start 0
  set summer-start spring-start + transition-length
  set autumn-start summer-start + 4 * transition-length
  set winter-start autumn-start + transition-length

  set season "winter"

  set cave-size 65
  set cave-color 122
  set contaminated-color red + 4
  set fungal-patch-size 20
  set fungal-patches 5

  set how-many-bats-to-start 30
  set percent-infected-to-start 0
  set average-infection-to-death-time (1 * transition-length)
  set average-recovery-time (3 * transition-length)
  set average-lifespan (15 * cycle-length)
  set average-fungal-threshold 15
  set immune-after-recovery? false


  set susceptible-bat-color white
  set immune-bat-color magenta
  set infected-bat-color red
  set dead-bat-color gray

  set adult-size 5
  set baby-size 2
  set adult-age cycle-length

  set birth-probability 0.005
  set adult-death-probability 0.0008
  set baby-death-probability 0.001

  set flash-time 20

  setup-bats
  setup-patches

  reset-ticks
end


to setup-bats
  set-default-shape turtles "bat1"
  let number-immune 0
  let number-infected ((how-many-bats-to-start - number-immune) * (percent-infected-to-start / 100))
  let number-susceptible (how-many-bats-to-start - number-immune - number-infected)

  ;; Create the immune, infected, and succeptible bats

  let start-age 0
  if allow-birth?
    [ set start-age adult-age + 1 ]

  create-turtles number-immune [
    create-default-bat
      start-age
      max-pxcor - random-float cave-size
      max-pycor - random-float cave-size
      false

    set susceptible? false
    set immune? true

    assign-bat-visible-traits
  ]


  create-turtles number-infected [
    create-default-bat
      start-age
      max-pxcor - random-float cave-size
      max-pycor - random-float cave-size
      false

    set infected? true
    set contagious? true
    set has-been-infected? true

    assign-bat-visible-traits
  ]

  create-turtles number-susceptible [
    create-default-bat
      start-age
      max-pxcor - random-float cave-size
      max-pycor - random-float cave-size
      false

    set susceptible? true

    assign-bat-visible-traits
  ]
end


to assign-bat-visible-traits
  ifelse (allow-birth?) and (adult? = false)
    [ set size baby-size ]
    [ set size adult-size ]

  (ifelse
    flashing? [
      ifelse flash-length <= flash-time [
        set size adult-size + 2
        let alternate-color susceptible-bat-color
        if immune-after-recovery?
          [ set alternate-color immune-bat-color]
        set color ifelse-value (color = infected-bat-color) [alternate-color] [infected-bat-color]
        set flash-length flash-length + 1
      ]
      [
        set size adult-size
        set flashing? false
        set flash-length 0
      ]
    ]
    dead? [
      set color dead-bat-color
    ]
    infected? [
      set color infected-bat-color
    ]
    susceptible? [
      set color susceptible-bat-color
    ]
    [  ; immune
      set color immune-bat-color
    ])

;  set label fungal-load

end


to create-default-bat [bat-age start-x start-y inherit-disease-traits?]
  set how-many-bats how-many-bats + 1

  setxy start-x start-y

  ;; these traits are inherited, only set them if this bat is not inheriting them
  if inherit-disease-traits? = false [
    set infected? false
    set susceptible? false
    set contagious? false
    set immune? false
  ]

  set cured? false
  set has-been-infected? false
  set dead? false
  set flashing? false
  set given-birth-this-year? false
  set adult? false

  set fungal-load 0

  set sex one-of ["male" "female"]

  set age bat-age
  if age > adult-age
    [ set adult? true ]

  ;; Set the lifespan to fall on a normal distribution around average lifespan
  set lifespan random-normal average-lifespan (average-lifespan / 4)

  (ifelse lifespan > (average-lifespan * 2)
    [ set lifespan (average-lifespan * 2) ]
  lifespan < 0
    [ set lifespan (average-lifespan / 2) ]
  )


  ;; Set the recovery time to fall on a normal distribution around the mean
  set recovery-time random-normal average-recovery-time (average-recovery-time / 4)

  (ifelse recovery-time > (average-recovery-time * 2)
    [ set recovery-time (average-recovery-time * 2) ]
  recovery-time < 0
    [ set recovery-time (average-recovery-time / 2) ]
  )


  ;; Set the infection-to-death time to fall on a normal distribution around the mean
  set infection-to-death-time random-normal average-infection-to-death-time (average-infection-to-death-time / 4)

  (ifelse infection-to-death-time > (average-infection-to-death-time * 2)
    [ set infection-to-death-time (average-infection-to-death-time * 2) ]
  infection-to-death-time < 0
    [ set infection-to-death-time (average-infection-to-death-time / 2) ]
  )


  ;; Set the threshold for infection to fall on a normal distribution around the mean
  set fungal-threshold floor (random-normal average-fungal-threshold (average-fungal-threshold / 4))

  (ifelse fungal-threshold > (average-fungal-threshold * 2)
    [ set fungal-threshold (average-fungal-threshold * 2) ]
  fungal-threshold < 0
    [ set fungal-threshold floor (average-fungal-threshold / 2) ]
  )

  set max-fungal-load (fungal-threshold * 2)

  ;; Bats recovery by reducing their fungal load.
  ;; This sets the probabilty of a unit reduction in fungal load so that,
  ;; in expectation, bats recover after their recovery time.
  set fungal-reduce-probability (fungal-threshold / recovery-time)
end


to setup-patches
  ;; Set defaults
  ask patches [
    set cave? false
    set border? false
    set cave-border? false
    set contaminated? false
  ]

  ;; Set the border of the world
  ask patches with [
    pxcor = max-pxcor or
    pxcor = min-pxcor or
    pycor = max-pycor or
    pycor = min-pycor
  ]
  [
    set border? true
  ]

  ;; Set the cave
  ask patches with [
    pxcor >= (max-pxcor - cave-size) and
    pycor >= (max-pycor - cave-size)
  ] [
    set cave? true
    set pcolor cave-color
  ]
  ask patch (mean [pxcor] of patches with [cave?] + 5) (max-pycor - 6) [
    set plabel "CAVE"
  ]

  ;; Draw a border around the cave
  ask patches with [
    pxcor = (max-pxcor - cave-size - 1) and
    pycor >= (max-pycor - cave-size - 1)
  ] [
    set cave-border? true
    set pcolor white
  ]
  ask patches with [
    pxcor >= (max-pxcor - cave-size - 1) and
    pycor = (max-pycor - cave-size - 1)
  ] [
    set cave-border? true
    set pcolor white
  ]

  ;; Set the contaminated patches - make sure one is near the center;
  ;; the others can be completely random, but separate from each other
  let cx mean [pxcor] of patches with [cave?]
  let cy mean [pycor] of patches with [cave?]
  let radius 5

  let random-near-cave-center one-of patches with [
    distancexy cx cy <= radius
  ]
  create-contaminated-area random-near-cave-center

  repeat (fungal-patches - 1) [
    let candidate nobody
    while [candidate = nobody] [
      let try-one one-of patches with [cave? and not contaminated?]
      let nearby nobody
      ask try-one
      [ set nearby patches in-radius (fungal-patch-size / 3 )
      ]
      if not any? nearby with [contaminated?] [
        set candidate try-one
      ]
    ]
    create-contaminated-area candidate
  ]


  ask patches with [ not cave? ]
  [
    set contaminated? false
  ]

  ask patches with [ contaminated? = true ]
  [
    set pcolor red + 4
  ]


  ask patch 0 (max-pycor - 6) [
    set plabel season
  ]

end


to create-contaminated-area [center-patch]
  let open-patches (list center-patch)
  let contaminated-patches []

  ;; grow until we reach the desired size
  while [length contaminated-patches < fungal-patch-size and not empty? open-patches] [
    let current one-of open-patches
    set open-patches remove current open-patches
    if not member? current contaminated-patches [
      set contaminated-patches lput current contaminated-patches
      ask current [
        set contaminated? true
      ]

      ;; add neighbors with some randomness
      ask current [
        ask neighbors4 with [not member? self contaminated-patches and random-float 1.0 < 0.8] [
          set open-patches lput self open-patches
        ]
      ]
    ]
  ]
end


to-report resistance-to-direct-infection
  report item position resistance ["Low" "Medium" "High"]
                                  [  0      85      95  ]
end


to-report resistance-to-indirect-infection
  report item position resistance ["Low" "Medium" "High"]
                                  [  0      85      95  ]
end


to-report tolerance-as-number
  report item position tolerance ["Low" "Medium" "High"]
                                 [  1      35      75  ]
end


to-report climate-as-number
  report item position climate ["Bad for the fungus" "Good for the fungus"]
                               [       -5                      8          ]
end

;;;
;;; GO PROCEDURES
;;;


to go
  set tmod ticks mod cycle-length

  set-season

  if all? turtles [ dead? ] [
    end-sim
    stop
  ]

  ; if all? patches [ not contaminated? ]
  ;  [ stop ]

  ask patches
    [ color-patches ]

  ask turtles with [ not dead? ] [
    if infected? [
      set infection-length infection-length + 1
    ]

    if contagious?
      [ direct-infect ]

    if not immune?
      [ indirect-infect ]

   if [cave? = false] of patch-here [
      set recovery-length recovery-length + 1
      reduce-fungal-load
    ]

   if allow-birth? [
     if (sex = "female") and (given-birth-this-year? = false) and ([cave? = false] of patch-here)
       [ maybe-give-birth ]
    ]

    move
    age-one-day
    maybe-die
    assign-bat-visible-traits
  ]

  grow-or-shrink-fungus

  tick
end


to set-season
  (ifelse
    tmod > winter-start [
      set season "winter"
      ask turtles [ set given-birth-this-year? false ]
    ]
    (tmod > autumn-start) and (tmod <= winter-start) [
      set season "autumn"
    ]
    (tmod > summer-start) and (tmod <= autumn-start) [
      set season "summer"
    ]
    tmod <= summer-start [
      set season "spring"
    ]
  )
end



to move
  (ifelse
    season = "spring" [
      (ifelse
        [cave? or cave-border?] of patch-here
        [
          set heading away-from-cave
        ]
        [border? = true] of patch-here
        [
          set heading away-from-border
        ]
        [
          rt 10 - random-float 20
        ]
      )
      fd floor (tmod / 10)
    ]
    season = "summer" [
      (ifelse
        [cave? or cave-border?] of patch-here
        [
          set heading away-from-cave
        ]
        [border? = true] of patch-here
        [
          set heading away-from-border
        ]
        [
          rt 10 - random-float 20
        ]
      )
      fd 5
    ]
    season = "autumn" [
      set heading towards-cave
      ; fd 5
      fd floor ((transition-length - (tmod - autumn-start)) / 3)
    ]
    season = "winter" [
    if [cave? = false] of patch-here
      [
        set heading towards-cave
        fd 2
      ]
    ]
    )
end


to-report towards-cave
  let target-x max-pxcor - random cave-size
  let target-y max-pycor - random cave-size

  let d-x target-x - xcor
  let d-y target-y - ycor

  ;; calculate absolute heading
  let absolute-heading atan d-x d-y

  report absolute-heading
end


to-report away-from-cave
  let repel-x max-pxcor
  let repel-y max-pycor

  let d-x xcor - repel-x
  let d-y ycor - repel-y

  let escape-heading atan d-x d-y + random-float 30 - 15

  report escape-heading
end


to-report away-from-border
  let away-heading heading + 100 - random-float 20

  report away-heading
end


to age-one-day
  set age age + 1
  if age > adult-age
    [ set adult? true ]
end


;; Direct infection can occur to any susceptible bat nearby an infected bat
to direct-infect
   let nearby-susceptible (other turtles in-radius 10) with [ susceptible? ]

   ask nearby-susceptible [
    let d distance myself
    let distance-factor 1

    let base-probability 100 - resistance-to-direct-infection
      ;; Inverse-square decay
      ; if d > 0
        ; [ set distance-factor 1 / (d ^ 2) ]

      ;; step-wise decay; better for cave?
      (ifelse
        d <= 2
          [ set distance-factor 1 ]
        d <= 5
          [ set distance-factor 0.5 ]
        d <= 10
          [ set distance-factor 0.1 ]
      )

    let final-probability base-probability * distance-factor

      if (fungal-load < max-fungal-load) and (random-float 100 < final-probability) [
        set fungal-load fungal-load + 1
        update-infected-status
      ]
    ]
end


;; Indirect infection can occur to any susceptible bat on a contaminated patch
to indirect-infect
  if ([contaminated?] of patch-here) and
     (fungal-load < max-fungal-load) and
     (random-float 100 > resistance-to-indirect-infection)
  [
    set fungal-load fungal-load + 1
    update-infected-status
  ]
end


to update-infected-status
  ;; If a susceptible bat's fungal load goes above below their threshold, they become infected
  if (susceptible? = true) and (fungal-load >= fungal-threshold) [
    set infected? true
    set contagious? true
    set susceptible? false
    set has-been-infected? true
    set infection-length 0
    set recovery-length 0
  ]

  ;; If an infected bat's fungal load drops below their threshold, they recover
  if (infected? = true) and (fungal-load < fungal-threshold) [
    set infected? false
    set contagious? false
    set cured? true

    set infection-length 0

    set flashing? true
    set flash-length 0

    ifelse immune-after-recovery? [
      set susceptible? false
      set immune? true
    ]
    [
      set susceptible? true
    ]
  ]
end


to reduce-fungal-load
  if ([cave? = false] of patch-here) and (random-float 1.0 < fungal-reduce-probability) [
    if fungal-load > 0
      [ set fungal-load fungal-load - 1 ]
    update-infected-status
  ]
end


to maybe-die
  ;; die due to infection
  let season-survival-prob tolerance-as-number / 100
  let daily-survival-prob exp ( ln(season-survival-prob) / (4 * transition-length) )

  ;; Die of infection
  if (infection-length > infection-to-death-time) and (random-float 1.0 > daily-survival-prob) [
    set dead? true
    set contagious? false
    set how-many-bats how-many-bats - 1
  ]

  ;; Die of natural causes
  if (dead? = false) and (allow-natural-death? = true) [
    if ( age > lifespan ) ; die from old age
      or ( ( adult? and (random-float 1.0 < adult-death-probability) )
      or ( not adult? and (random-float 1.0 < baby-death-probability) ) ) ; die due to other factors
      [
        set dead? true
        set contagious? false
        set how-many-bats how-many-bats - 1
      ]
  ]
end



to maybe-give-birth
   if random-float 1.0 < birth-probability [
     hatch 1 [
       create-default-bat 0 xcor ycor true
       set susceptible? true
     ]

    set given-birth-this-year? true
  ]
end


to grow-or-shrink-fungus

  let growth-prob 0.00001
  let shrink-prob 0.00001

  ;; Growth is more likely if climate > 0, Shrinkage is more likely if climate < 0
  (ifelse
    climate-as-number > 0 [
      set growth-prob 0.001 * climate-as-number
      set shrink-prob 0
      ; set shrink-prob 0.001 / (climate-as-number)
    ]
    climate-as-number < 0 [
      set growth-prob 0.001 / (abs climate-as-number)
      set shrink-prob 0.001 * (abs climate-as-number)
    ]
    climate-as-number = 0 [
      set growth-prob 0.001
      set shrink-prob 0.001
    ]
  )


  ; Grow fungus
  let new-growth patches with [contaminated?]
  ask new-growth [
    ask neighbors4 with [
      not contaminated? and cave? and random-float 1.0 < growth-prob
    ] [
      set contaminated? true
      set pcolor contaminated-color
    ]
  ]

  ; Shrink fungus
  ask patches with [contaminated? and random-float 1.0 < shrink-prob ] [
    set contaminated? false
    set pcolor cave-color
  ]
end


to color-patches
  if not contaminated? and not (cave? or cave-border?)
  [
    (ifelse
      season = "winter" [
        set pcolor winter-color
      ]
      season = "autumn" [
        ;; summer -> winter transition
        let factor (tmod - (cycle-length / 2)) / transition-length
        let idx floor ((1 - factor) * (length season-color-scale - 1))
        set pcolor item idx season-color-scale
      ]
      season = "summer" [
        set pcolor summer-color
      ]
      season = "spring" [
        ;; winter -> summer transition
        let factor tmod / transition-length
        let idx floor (factor * (length season-color-scale - 1))
        set pcolor item idx season-color-scale
      ]
    )
  ]

  ask patch 0 (max-pycor - 6) [
    set plabel season
  ]
end


to end-sim
  ask patches with [not contaminated? and not (cave? or cave-border?)] [
    set pcolor infected-bat-color
    ask patch 0 (max-pycor - 6) [
      set plabel "** all dead **"
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
705
18
1503
817
-1
-1
3.93035
1
25
1
1
1
0
0
0
1
-100
100
-100
100
1
1
1
days
30.0

BUTTON
30
136
293
222
Set the scene
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
390
137
653
223
Start
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
1559
359
1894
551
Sick and healthy
days
how many bats
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "plot (count turtles with [ infected? ] )"
"Healthy" 1.0 0 -10899396 true "" "plot (count turtles with [ not infected? and not dead?])"
"Dead" 1.0 0 -7500403 true "" "plot (count turtles with [ dead? ])"

PLOT
1559
144
1891
335
% of cave contaminated
days
% of cave
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"% contaminated" 1.0 0 -2674135 true "" "plot ((count patches with [ contaminated? ] / (cave-size ^ 2)) * 100)"

MONITOR
1654
580
1824
625
Average lifespan (in years)
( mean [age] of turtles ) / cycle-length
1
1
11

TEXTBOX
365
492
678
534
Resistance is how well the bat can fight off the\nfungus and keep it from growing on its body
11
0.0
1

TEXTBOX
364
603
672
654
Tolerance is how well the bat can stay alive\neven though the fungus is still on its body
11
0.0
1

TEXTBOX
364
709
676
762
The climate affects how well the fungus grows\nin the cave
11
0.0
1

TEXTBOX
83
39
316
151
Press \"Set the scene\" \nto build a fresh cave \n          of bats. 
22
0.0
1

CHOOSER
117
494
354
539
Resistance
Resistance
"Low" "High"
0

CHOOSER
117
602
354
647
Tolerance
Tolerance
"Low" "High"
0

CHOOSER
117
708
354
753
Climate
Climate
"Bad for the fungus" "Good for the fungus"
1

TEXTBOX
102
385
638
418
Try changing some of these to see what happens!
22
0.0
1

TEXTBOX
1559
74
1892
154
These plots can help you keep\n    track of what's happening
22
0.0
1

MONITOR
1654
645
1824
690
Age of colony (in years)
ticks / cycle-length
1
1
11

TEXTBOX
8
17
72
136
1
100
15.0
1

TEXTBOX
376
17
445
136
2
100
15.0
1

TEXTBOX
454
52
634
146
 Press \"Start\" to \nwatch them go!
22
0.0
1

TEXTBOX
140
385
240
415
changing
22
15.0
1

TEXTBOX
32
340
98
459
3
100
15.0
1

TEXTBOX
199
465
292
487
Resistance
18
15.0
1

TEXTBOX
542
492
609
523
fight off
11
15.0
1

TEXTBOX
204
574
293
595
Tolerance
18
15.0
1

TEXTBOX
537
603
618
627
stay alive
11
15.0
1

TEXTBOX
214
682
289
704
Climate
18
15.0
1

TEXTBOX
153
39
303
66
Set the scene
22
15.0
1

TEXTBOX
530
52
582
79
Start
22
15.0
1

TEXTBOX
531
709
630
744
fungus grows
11
15.0
0

TEXTBOX
1665
104
1886
158
what's happening
22
15.0
1

@#$#@#$#@
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

bat1
true
0
Rectangle -7500403 true true 120 120 135 210
Rectangle -7500403 true true 135 135 150 225
Rectangle -7500403 true true 150 120 165 210
Rectangle -1 true false 165 135 240 120
Rectangle -7500403 true true 165 150 225 165
Rectangle -7500403 true true 180 135 240 150
Rectangle -7500403 true true 195 120 255 135
Rectangle -7500403 true true 210 105 270 120
Rectangle -7500403 true true 150 165 225 180
Rectangle -1 true false 165 180 210 195
Rectangle -7500403 true true 165 180 210 195
Rectangle -7500403 true true 45 135 105 150
Rectangle -7500403 true true 30 120 90 135
Rectangle -7500403 true true 15 105 75 120
Rectangle -7500403 true true 60 150 120 165
Rectangle -7500403 true true 60 165 120 180
Rectangle -7500403 true true 75 180 120 195
Rectangle -1184463 true false 120 135 135 150
Rectangle -1184463 true false 150 135 165 150

bat2
true
0
Rectangle -7500403 true true 105 105 180 210
Rectangle -7500403 true true 105 90 120 105
Rectangle -7500403 true true 165 90 180 105
Rectangle -7500403 true true 90 135 105 195
Rectangle -7500403 true true 180 135 195 195
Rectangle -7500403 true true 120 210 135 225
Rectangle -7500403 true true 150 210 165 225
Rectangle -7500403 true true 75 120 90 180
Rectangle -7500403 true true 60 105 75 165
Rectangle -7500403 true true 45 120 60 180
Rectangle -7500403 true true 30 135 45 195
Rectangle -7500403 true true 15 150 30 210
Rectangle -7500403 true true 60 165 75 195
Rectangle -7500403 true true 195 120 210 180
Rectangle -7500403 true true 210 105 225 165
Rectangle -7500403 true true 225 120 240 180
Rectangle -7500403 true true 240 135 255 195
Rectangle -7500403 true true 255 150 270 210
Rectangle -7500403 true true 210 165 225 195
Rectangle -1184463 true false 120 120 135 135
Rectangle -1184463 true false 150 120 165 135

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

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

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

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

dot
false
0
Circle -7500403 true true 90 90 120

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

line
true
0
Line -7500403 true 150 0 150 300

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

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

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
NetLogo 6.2.2
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
