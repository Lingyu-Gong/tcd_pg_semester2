extensions [array table]

globals [
  ;;number of turtles with each strategy


  ;;number of interactions by each strategy
  num-random-games
  num-cooperate-games
  num-defect-games
  num-tit-for-tat-games
  num-unforgiving-games
  num-tit-for-tat-forgiveness-games
  num-win-stay-lose-shift-games

  ;;number of games to play
  num-games
  end-probability ;;probability of sequence ending
  end-sequence-method ;;fixed or probability based


  ;;turtle memory mode
  partner-list-on

  ;;Final edit by GONG
  ;;total
  total-cooperation
  total-betrayal

  ;;total times
  ;;total-cooperate-games
  ;;total-defect-games


  ;;Final edit by GONG
  total-games
  random-wins
  random-games
  cooperate-wins  ;;Record the number of victories in the always co-operative strategy
  cooperate-games ;;Record the number of games that always co-operate with the strategy
  defect-wins
  defect-games
  tit-for-tat-wins
  tit-for-tat-games
  unforgiving-wins
  unforgiving-games



  ;; Counter for comparison of stratagies
  outcomes-dict


  ;; conveniance dict to map strategy to array index
  strategy-dict

  ;;dictionary to map strat name score
  strategy-scores
  ;;dictionary to map strat name to num agents
  strategy-num-agents
  ;;dictionary to map strat name to boolean determining if memory needed
  strategy-memory-type
  ;;dictionary to map strat name to colour
  strategy-colour
]

;; Create Breeds for specific attributes

;; single_memory_turtles are turtles who can remember the previous game a partner played
breed [single_memory_turtles single_memory_turtle]

;; all_partner_memory_turtles are turtles who can remember the previous game any past partner played
breed [all_partner_memory_turtles all_partner_memory_turtle]

turtles-own [
  score
  strategy
  defect-now?
  partner-defected? ;;action of the partner
  partnered?        ;;am I partnered?
  partner           ;;WHO of my partner (nobody if not partnered)
  partner-history          ;;Most recent action of partners, true if defected
  partner-game-counter      ;;counter for number of games against a partner
  checked-for-end?  ;; to prevent both partners doing a probability check to end game
  last-action       ;; "cooperate" or "defect"
  current-score     ;; The cumilitave score each turtle gets
  cooperation-count ;; Each turtles local count of their cooperations
  betrayal-count    ;; Each turtles local count of their defects
]

single_memory_turtles-own [
  last-move-cooperate?      ;;wsls strategy
  chance-to-forgive?        ;;tft forgiveness
]

all_partner_memory_turtles-own [
  last-move-cooperate?           ;;wsls strategy
  last-move-cooperate-list  ;;wsls strategy
  chance-to-forgive? ;;tft forgiveness
  chance-to-forgive-list ;;tft forgiveness
]

;;;;;;;;;;;;;;;;;;;;;;
;;;Setup Procedures;;;
;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  update-game-settings;;set info for the strategies
  setup-turtles ;;setup the turtles and distribute them randomly
  setup-outcome-lists ;; setup a table(dict) of lists of outcomes for each strategy
  ;; Final edit by GONG
  set total-cooperation 0
  set total-betrayal 0
  set total-games 0
  set random-wins 0
  set random-games 0
  set cooperate-wins 0
  set cooperate-games 0
  set defect-wins 0
  set defect-games 0
  set tit-for-tat-wins 0
  set tit-for-tat-games 0
  set unforgiving-wins 0
  set unforgiving-games 0
  reset-ticks
end




to update-game-settings
  set num-games n-games
  set end-sequence-method sequence-end-method
  set end-probability probability_sequence_ends
  ifelse partner-list = true[
    set partner-list-on true
  ]
  [
    set partner-list-on false
  ]

  set strategy-scores table:make
  table:put strategy-scores "random"  0
  table:put strategy-scores "cooperate" 0
  table:put strategy-scores "defect"  0
  table:put strategy-scores "tit-for-tat" 0
  table:put strategy-scores "unforgiving" 0
  table:put strategy-scores "tit-for-tat-forgiveness" 0
  table:put strategy-scores "win-stay-lose-shift" 0

  set strategy-num-agents table:make
  table:put strategy-num-agents "random"  n-random
  table:put strategy-num-agents "cooperate" n-cooperate
  table:put strategy-num-agents "defect"  n-defect
  table:put strategy-num-agents "tit-for-tat" n-tit-for-tat
  table:put strategy-num-agents "unforgiving" n-unforgiving
  table:put strategy-num-agents "tit-for-tat-forgiveness" n-tit-for-tat-forgiveness
  table:put strategy-num-agents "win-stay-lose-shift" n-win-stay-lose-shift

  set strategy-memory-type table:make
  table:put strategy-memory-type "random"  false
  table:put strategy-memory-type "cooperate" false
  table:put strategy-memory-type "defect"  false
  table:put strategy-memory-type "tit-for-tat" true
  table:put strategy-memory-type "unforgiving" true
  table:put strategy-memory-type "tit-for-tat-forgiveness" true
  table:put strategy-memory-type "win-stay-lose-shift" true

  set strategy-colour table:make
  table:put strategy-colour "random"  gray - 1
  table:put strategy-colour "cooperate" red
  table:put strategy-colour "defect"  blue
  table:put strategy-colour "tit-for-tat" lime
  table:put strategy-colour "unforgiving" turquoise - 1
  table:put strategy-colour "tit-for-tat-forgiveness" yellow
  table:put strategy-colour "win-stay-lose-shift" orange

end



;;setup the turtles and distribute them randomly
to setup-turtles
  make-turtles ;;create the appropriate number of turtles playing each strategy
  setup-common-variables ;;sets the variables that all turtles share
end

;;create the appropriate number of turtles playing each strategy
to make-turtles
  let strategy-names table:keys strategy-num-agents ;;list of strategy names
  foreach strategy-names [strategy-name ->
    let num-to-create table:get strategy-num-agents strategy-name
    let colour table:get strategy-colour strategy-name
    let memory-needed table:get strategy-memory-type strategy-name
    adjust-turtle-counts-for-strategy strategy-name num-to-create colour memory-needed
  ]
end

;;this is used for creating/deleting more turtles during or before runtime.
;; currently, it does not release during run time so this is only being used before runtime

to adjust-turtle-counts-for-strategy [strategy-name desired-count colour needsMemory?]
  let current-count count turtles with [strategy = strategy-name]
  if current-count != desired-count [
    ifelse desired-count > current-count [
      ifelse needsMemory? = false[
      create-normal-turtles-for-strategy (desired-count - current-count) strategy-name colour
      ][
        ifelse partner-list-on = true[
        create-all-memory-turtles-for-strategy (desired-count - current-count) strategy-name colour
        ][
          create-single-memory-turtles-for-strategy (desired-count - current-count) strategy-name colour
        ]
      ]
    ]  [
      let turtles-to-release n-of (current-count - desired-count) turtles with [strategy = strategy-name]

      ask turtles-to-release [release-partners]
      ask turtles-to-release [die]
    ]
    table:put strategy-num-agents strategy-name desired-count
  ]
end

to create-normal-turtles-for-strategy [num-to-create strategy-name colour]
  create-turtles num-to-create [
    set strategy strategy-name
    set color colour
    set score 0
    set partnered? false
    set partner nobody
    setxy random-xcor random-ycor
    set current-score 0

  ]
end

to create-single-memory-turtles-for-strategy [num-to-create strategy-name colour]
   let max-who ifelse-value (any? turtles) [ max [who] of turtles ] [ -1 ] ;;max who number before creating more
    create-single_memory_turtles num-to-create[
    set strategy strategy-name
    set color colour
    set score 0
    set partnered? false
    set partner nobody
    setxy random-xcor random-ycor
    set current-score 0
    set partner-history false
    set last-move-cooperate? false
    set chance-to-forgive?   true     ;;tft forgiveness
  ]
   let new-turtles turtles with [who > max-who]
  ask new-turtles[ set partner-history false]
end

to create-all-memory-turtles-for-strategy [num-to-create strategy-name colour]
  let max-who ifelse-value (any? turtles) [ max [who] of turtles ] [ -1 ] ;;max who number before creating more
  create-all_partner_memory_turtles num-to-create[
    set strategy strategy-name
    set color colour
    set score 0
    set partnered? false
    set partner nobody
    setxy random-xcor random-ycor
    set current-score 0
    set last-move-cooperate? false
    set chance-to-forgive?   true     ;;tft forgiveness
  ]
  let new-turtles turtles with [who > max-who]
  ask new-turtles [setup-history-lists]
end


to setup-outcome-lists
  let strategy-names table:keys strategy-scores
  ;; create table of the names of each stratagy and their index in the outcome lists
  set outcomes-dict table:make
  foreach strategy-names[ [x] ->
    table:put outcomes-dict x (array:from-list n-values (length strategy-names) [0])
  ]

  ;; create table of a list for each stratagy to track win/loss with other stratagies
  set strategy-dict table:make
  let i 0
  foreach strategy-names[ [x] ->
    table:put strategy-dict x i
    set i (i + 1)
  ]


end


;;set the variables that all turtles share
to setup-common-variables
  ask turtles [
    set score 0
    set partnered? false
    set partner nobody
    setxy random-xcor random-ycor
    set current-score 0
  ]

  ;; Set the variables that are common only to specific breeds
  ask single_memory_turtles[
    set partner-history false
    set chance-to-forgive? true
     set partner-history false
    set last-move-cooperate? false    ;; start with defect wsls
  ]

  ask all_partner_memory_turtles[
    setup-history-lists ;;initialize PARTNER-HISTORY list in all turtles
  ]

end


;;initialize PARTNER-HISTORY list in all turtles
;; only applies to all_partner_memory_turtles
to setup-history-lists
  let num-turtles count turtles

  let default-history [] ;;initialize the DEFAULT-HISTORY variable to be a list
  let default-true-list n-values num-turtles [true] ;;initialize the default-true-list variable to be a list OF BOOLEAN
  let default-false-list n-values num-turtles [false] ;;initialize the default-false-list variable to be a list OF BOOLEAN

  ;;create a list with NUM-TURTLE elements for storing partner histories
  repeat num-turtles [ set default-history (fput false default-history) ]

  ;;give each turtle a copy of this list for tracking partner histories
  ask all_partner_memory_turtles [ set partner-history default-history
    set chance-to-forgive-list default-true-list
  set last-move-cooperate-list default-false-list
  ]


end


;;;;;;;;;;;;;;;;;;;;;;;;
;;;Runtime Procedures;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to go
  clear-last-round
  ask turtles [ partner-up ]                        ;; have turtles try to find a partner
  let partnered-turtles turtles with [ partnered? ]
  ask partnered-turtles [ select-action ]           ;; all partnered turtles select action
  ask partnered-turtles [ play-a-round ]            ;; turtles play a round based on their action
  increment-game-counter                            ;; increment game counter for all turtles
  do-scoring                                        ;; calculate scores based on actions

  ;; Calculate win rate for the random strategy
  calculate-random-win-rate

  ;; Calculate win rate for the cooperate strategy
  calculate-cooperate-win-rate

  ;; Calculate win rate for the defect strategy
  calculate-defect-win-rate

  calculate-tit-for-tat-win-rate

  calculate-unforgiving-win-rate

  tick
end



;to calculate-cooperate-win-rate
;  ask turtles with [strategy = "cooperate"] [
;    set cooperate-games cooperate-games + 1
;    ifelse (score = both-cooperate) [
;      set cooperate-wins cooperate-wins + 1
;      show (word "Incrementing wins: " cooperate-wins)
;    ]  [
;      show (word "Score not match both-cooperate: " score)
;    ]
;  ]
;  ;; print the current counts for debugging
;  print (word "Current cooperate-wins: " cooperate-wins)
;  print (word "Current cooperate-games: " cooperate-games)
;  ;; update the monitor every 10 rounds
;  if (cooperate-games mod 10 = 0) [
;    let win-rate calculate-win-rate cooperate-wins cooperate-games
;    output-show (word "After " cooperate-games " rounds, the win rate of the cooperate strategy is: " win-rate "%")
;  ]
;end

to calculate-random-win-rate
  ask turtles with [strategy = "random"] [
    if score >= both-cooperate [
      set random-wins random-wins + 1
    ]
    set random-games random-games + 1  ;; increment the game count for the random strategy
  ]
  ;; update the monitor every 10 rounds
  if (total-games mod 10 = 0) [
    let win-rate calculate-win-rate random-wins random-games
    output-show (word "After " random-games " rounds, the win rate of the random strategy is: " win-rate "%")
  ]
end

to calculate-cooperate-win-rate
  ask turtles with [strategy = "cooperate"] [
    if score >= both-cooperate [
      set cooperate-wins cooperate-wins + 1
    ]
    set cooperate-games cooperate-games + 1  ;; increment the game count for the cooperate strategy
  ]
  ;; update the monitor every 10 rounds
  if (total-games mod 10 = 0) [
    let win-rate calculate-win-rate cooperate-wins cooperate-games
    output-show (word "After " cooperate-games " rounds, the win rate of the cooperate strategy is: " win-rate "%")
  ]
end

to calculate-defect-win-rate
  ;; calculate the victory count for the defect strategy
  ask turtles with [strategy = "defect"] [
    if score > both-cooperate [
      ;; we don't increment defect-wins, as the score cannot be higher than 10
    ]
    set defect-games defect-games + 1
  ]

  ;; update the win rate
  if defect-games > 0 [
    let win-rate calculate-win-rate defect-wins defect-games
    ;; display the win rate on the interface after every 10 rounds
    if (defect-games mod 10 = 0) [
      output-show (word "After " defect-games " rounds, the win rate of the defect strategy is: " win-rate "%")
    ]
  ]
end

to calculate-tit-for-tat-win-rate
  ;; calculate the victory count for the tit-for-tat strategy
  ask turtles with [strategy = "tit-for-tat"] [
    if score >= both-cooperate [
      set tit-for-tat-wins tit-for-tat-wins + 1  ; record the victory count
    ]
    set tit-for-tat-games tit-for-tat-games + 1  ; game count
  ]

  ;; update the win rate
  if tit-for-tat-games > 0 [
    let win-rate calculate-win-rate tit-for-tat-wins tit-for-tat-games
    ;; display the win rate on the interface after every 10 rounds
    if (tit-for-tat-games mod 10 = 0) [
      output-show (word "After " tit-for-tat-games " rounds, the win rate of the tit-for-tat strategy is: " win-rate "%")
    ]
  ]
end

to calculate-unforgiving-win-rate
  ;; calculate the victory count for the unforgiving strategy
  ask turtles with [strategy = "unforgiving"] [
    if score >= both-cooperate [
      set unforgiving-wins unforgiving-wins + 1  ; record the victory count
    ]
    set unforgiving-games unforgiving-games + 1  ; game count
  ]

  ;; update the win rate
  if unforgiving-games > 0 [
    let win-rate calculate-win-rate unforgiving-wins unforgiving-games
    ;; display the win rate on the interface after every 10 rounds
    if (unforgiving-games mod 10 = 0) [
      output-show (word "After " unforgiving-games " rounds, the win rate of the unforgiving strategy is: " win-rate "%")
    ]
  ]
end



to clear-last-round
  let partnered-turtles turtles with [ partnered? ]
  ask partnered-turtles [
    ifelse sequence-end-method = "Fixed number" [
	  ;; Fixed number based ending
    if partner-game-counter >= n-games [

      release-partners
      set partner-game-counter 0  ;; Reset the interaction counter
    ]
    ]
    [
      if checked-for-end? = false[
        ;;probability based end
        let random-probability random-float 1.0
        ifelse random-probability < (end-probability ) [  ;;divide by 2 because probability of game ending is when either agent fails this check
          release-partners
          set partner-game-counter 0  ;; Reset the interaction counter
        ]
        [
          ;;to prevent both partners checking for end
          if partnered?[
          set checked-for-end?  true
           ask partner [
            set checked-for-end? true
          ]
          ]
        ]
      ]
    ]
  ]
  ;;resetting end check
   ask turtles [
      set checked-for-end? false
    ]
end

;;release partner and turn around to leave
to release-partners
  if partnered? [
    ; If the turtle has a partner, release them, partner might have died
    if partner != nobody [
    ask partner [
      set partnered? false
      set partner nobody
      rt 180
      set label ""
      if breed = single_memory_turtles[ ;;resetting chance to forgive for new partner
        set chance-to-forgive? true
          set last-move-cooperate? false ;;false to start next round with defect
      ]

  ]
    ]
  ]
  set partnered? false
  set partner nobody
  rt 180
  set label ""
  if breed = single_memory_turtles[ ;;resetting chance to forgive for new partner
        set chance-to-forgive? true
       set last-move-cooperate? false
      ]


end

;;have turtles try to find a partner
;;Since other turtles that have already executed partner-up may have
;;caused the turtle executing partner-up to be partnered,
;;a check is needed to make sure the calling turtle isn't partnered.

to partner-up ;;turtle procedure
  if (not partnered?) [              ;;make sure still not partnered
    rt (random-float 90 - random-float 90) fd 1     ;;move around randomly
    set partner one-of (turtles-at -1 0) with [ not partnered? ]
    if partner != nobody [              ;;if successful grabbing a partner, partner up
      set partnered? true
      set heading 270                   ;;face partner
      ask partner [
        set partnered? true
        set partner myself
        set heading 90
        set partner-game-counter 0
      ]
    ]
  ]
end


;;choose an action based upon the strategy being played
to select-action ;;turtle procedure
  if strategy = "random" [ act-randomly ]
  if strategy = "cooperate" [ cooperate ]
  if strategy = "defect" [ defect ]
  if strategy = "tit-for-tat" [
    ifelse partner-list-on = true[
      tit-for-tat-with-list
    ]
    [
      tit-for-tat
    ]
  ]
  if strategy = "unforgiving" [
    ifelse partner-list-on = true[
      unforgiving-with-list
    ]
    [
      unforgiving
    ]
  ]
  if strategy = "tit-for-tat-forgiveness" [
    ifelse partner-list-on = true[
      tit-for-tat-forgiveness-with-list
    ]
    [
      tit-for-tat-forgiveness
    ]
  ]
  if strategy = "win-stay-lose-shift" [
    ifelse partner-list-on = true[
      win-stay-lose-shift-with-list
    ]
    [
      win-stay-lose-shift
    ]
  ]

  ;; Update total cooperation and defect counts
  ifelse defect-now? = false[
    set total-cooperation total-cooperation + 1
    set cooperation-count cooperation-count + 1
    show (word "Cooperation count for turtle " who " is now " cooperation-count)
  ] [
    set total-betrayal total-betrayal + 1
    set betrayal-count betrayal-count + 1
    show (word "Betrayal count for turtle " who " is now " betrayal-count)
  ]


end


to play-a-round ;;turtle procedure
  get-payoff     ;;calculate the payoff for this round
  update-history ;;store the results for next time
end


;;calculate the payoff for this round and
;;display a label with that payoff.
to get-payoff

  set partner-defected? [defect-now?] of partner
  ifelse partner-defected? [
    ifelse defect-now? [
      set score (score + both-defect) set label both-defect  ;;win for both

    ] [
      set score (score + solo-cooperate) set label solo-cooperate  ;;win for cooperator
    ]

    ;; If the partner defects, we always win
    let partner-strategy [strategy] of partner
    let ptr-strat-idx (table:get strategy-dict partner-strategy)  ;; get the index of the partners strategy
    array:set (table:get outcomes-dict strategy) ptr-strat-idx ((array:item (table:get outcomes-dict strategy) ptr-strat-idx) + 1)  ;; increment the number at this index by 1
  ] [
    ifelse defect-now? [
      set score (score + solo-defect) set label solo-defect  ;; loss for defector
    ] [
      set score (score + both-cooperate) set label both-cooperate ;;loss for both
    ]

    ;; If partner Cooperates, we always lose
    let partner-strategy [strategy] of partner
    let ptr-strat-idx (table:get strategy-dict partner-strategy)  ;; get index of the partners strategy
    array:set (table:get outcomes-dict strategy) ptr-strat-idx ((array:item (table:get outcomes-dict strategy) ptr-strat-idx) - 1)  ;; increment the number at this index by 1
  ]

end

;;increments counter for games against partner
to increment-game-counter
   let partnered-turtles turtles with [ partnered? ]
  ask partnered-turtles [
    set partner-game-counter (partner-game-counter + 1)
  ]
end
;;update PARTNER-HISTORY based upon the strategy being played
to update-history
  if strategy = "random" [ act-randomly-history-update ]
  if strategy = "cooperate" [ cooperate-history-update ]
  if strategy = "defect" [ defect-history-update ]
  if strategy = "tit-for-tat" [
    ifelse partner-list-on = true[
      tit-for-tat-with-list-history-update
    ]
    [
      tit-for-tat-history-update
    ]
  ]
  if strategy = "unforgiving" [
    ifelse partner-list-on = true[
      unforgiving-with-list-history-update
    ]
    [
      unforgiving-history-update
    ]
  ]
  if strategy = "tit-for-tat-forgiveness" [
    ifelse partner-list-on = true[
      tit-for-tat-forgiveness-with-list-history-update
    ]
    [
      tit-for-tat-forgiveness-history-update
    ]
  ]
  if strategy = "win-stay-lose-shift" [
    ifelse partner-list-on = true[
      win-stay-lose-shift-with-list-history-update
    ]
    [
      win-stay-lose-shift-history-update
    ]
  ]
end



;;;;;;;;;;;;;;;;
;;;Strategies;;;
;;;;;;;;;;;;;;;;

;;All the strategies are described in the Info tab.

to act-randomly
  set num-random-games num-random-games + 1
  ifelse (random-float 1.0 < 0.5) [
    set defect-now? false
  ] [
    set defect-now? true

  ]
end

to act-randomly-history-update
;;uses no history- this is just for similarity with the other strategies
end

;; Always cooperate
to cooperate
  set num-cooperate-games num-cooperate-games + 1
  ;; Final edit by GONG
  set defect-now? false
end

to cooperate-history-update
;;uses no history- this is just for similarity with the other strategies
end

;; Always defect
to defect
  set num-defect-games num-defect-games + 1
  set defect-now? true
  ;; Final edit by GONG

end

to defect-history-update
;;uses no history- this is just for similarity with the other strategies
end

;; If partner defected last time, defect. Otherwise cooperate
;; This only applies to the single_memory_turtles
to tit-for-tat
  set num-tit-for-tat-games num-tit-for-tat-games + 1
  ifelse (partner-history) [
    ;; Final edit by GONG
    set defect-now? true
  ] [
    set defect-now? false
  ]
end

;; store the most recent action done by partner
to tit-for-tat-history-update
  set partner-history partner-defected?
end

;; If partner defected last time, defect. Otherwise cooperate
;; This only applies to the all_partner_memory_turtles
to tit-for-tat-with-list
  set num-tit-for-tat-games num-tit-for-tat-games + 1
  set partner-defected? item ([who] of partner) partner-history
  ifelse (partner-defected?) [
    set defect-now? true
  ] [
    set defect-now? false
  ]
end

;; store the most recent action done by partner to the list
to tit-for-tat-with-list-history-update
  set partner-history
    (replace-item ([who] of partner) partner-history partner-defected?)
end

;; If parnter ever defects, always defect
;; This only applies to the single_memory_turtles
to unforgiving
  set num-unforgiving-games num-unforgiving-games + 1
  ifelse (partner-history)[
    set defect-now? true
  ] [
    set defect-now? false
  ]
end

;; If partner defects in the past set of games, remember this
to unforgiving-history-update
  if partner-defected? [
    set partner-history  partner-defected?
  ]
end


;; If parnter ever defects, always defect
;; This only applies to the all_partner_memory_turtles
to unforgiving-with-list
  set num-unforgiving-games num-unforgiving-games + 1
  set partner-defected? item ([who] of partner) partner-history
  ifelse (partner-defected?)[
    set defect-now? true
  ] [
    set defect-now? false
  ]
end

;; If partner ever defects, remember this
to unforgiving-with-list-history-update
  if partner-defected? [
    set partner-history
      (replace-item ([who] of partner) partner-history partner-defected?)
  ]
end

;; If partner defected last time, forgive once. Otherwise cooperate
;; This only applies to the single-memory-tit-for-tat-forgiveness turtles
to tit-for-tat-forgiveness
  set num-tit-for-tat-forgiveness-games num-tit-for-tat-forgiveness-games + 1
  ifelse (partner-defected? = true) [
    ifelse (chance-to-forgive?) [  ;; If partner defected only once or less
      set defect-now? false  ;; Forgive and cooperate
      set chance-to-forgive? false
    ] [
      set defect-now? true ;; Retaliate
    ]
  ]
  [
    set defect-now? false  ;; cooperate
  ]
end

;; store the most recent action done by partner
to tit-for-tat-forgiveness-history-update
  set partner-history partner-defected?
end

;; If partner defected last time, defect. Otherwise cooperate
;; This only applies to the all-memory-tit-for-tat-forgiveness turtles
to tit-for-tat-forgiveness-with-list
  set num-tit-for-tat-forgiveness-games num-tit-for-tat-forgiveness-games + 1
  set partner-defected? item ([who] of partner) partner-history
  set chance-to-forgive? item ([who] of partner) chance-to-forgive-list
  ifelse (partner-defected? = true) [
    ifelse (chance-to-forgive?) [  ;; If partner defected only once or less
      set defect-now? false  ;; Forgive and cooperate
      set chance-to-forgive? false
    ] [
      set defect-now? true ;; Retaliate
    ]
  ]
  [
    set defect-now? false  ;; cooperate
  ]
end
;; store the most recent action done by partner to the list
to tit-for-tat-forgiveness-with-list-history-update
  set partner-history
    (replace-item ([who] of partner) partner-history partner-defected?)
  set chance-to-forgive-list
    (replace-item ([who] of partner) chance-to-forgive-list chance-to-forgive?)
end


;; This only applies to the single-memory-win-stay-lose-shift turtles
;; if partner cooperated last round, keep doing what you did
;; if partner defected last time, change what you did
to win-stay-lose-shift
   set num-win-stay-lose-shift-games num-win-stay-lose-shift-games + 1

   ifelse (partner-defected? = true)[
      ifelse(last-move-cooperate? = true)[
        set defect-now? true
        set last-move-cooperate? false
    ][
      set defect-now? false
      set last-move-cooperate? true
    ]
  ]
  [
    set defect-now? not last-move-cooperate? ;;partner did not defect, either we both cooperated or I talked and they didnt. Do the same as before
  ]
end

;; store the most recent action done by partner
to win-stay-lose-shift-history-update

end


;; This only applies to the all-memory-win-stay-lose-shift turtles
to win-stay-lose-shift-with-list
  set num-win-stay-lose-shift-games num-win-stay-lose-shift-games + 1
  set partner-defected? item ([who] of partner) partner-history
  set last-move-cooperate? item ([who] of partner) last-move-cooperate-list
   ifelse (partner-defected? = true)[
      ifelse(last-move-cooperate? = true)[
        set defect-now? true
        set last-move-cooperate? false
    ][
      set defect-now? false
      set last-move-cooperate? true
    ]
  ]
  [
    set defect-now? not last-move-cooperate? ;;partner did not defect, either we both cooperated or I talked and they didnt. Do the same as before
  ]
end

to win-stay-lose-shift-with-list-history-update
 set partner-history
    (replace-item ([who] of partner) partner-history partner-defected?)
  set last-move-cooperate-list
    (replace-item ([who] of partner) last-move-cooperate-list last-move-cooperate?)

end

;;;;;;;;;;;;;;;;;;;;;;;;;
;;;Plotting Procedures;;;
;;;;;;;;;;;;;;;;;;;;;;;;;

;;calculate the total scores of each strategy
to do-scoring
  foreach table:keys strategy-scores [strategy-name ->
    let strategy-info table:get strategy-scores strategy-name
    let turtle-count table:get strategy-num-agents strategy-name
    let new-score calc-score strategy-name turtle-count

    ;; Update the score in the dictionary
    table:put strategy-scores strategy-name new-score
  ]
end

;; returns the total score for a strategy if any turtles exist that are playing it
to-report calc-score [strategy-type num-with-strategy]
  ifelse num-with-strategy > 0 [
    report (sum [ score ] of (turtles with [ strategy = strategy-type ]))
  ] [
    report 0
  ]
end


to-report cooperation-rate [given-strategy]
  let total-turtles-with-strategy count turtles with [strategy = given-strategy]
  if total-turtles-with-strategy > 0 [
    let total-cooperate count turtles with [strategy = given-strategy and not defect-now?]
    report total-cooperate / total-turtles-with-strategy
  ]
  report 0
end


to-report calculate-win-rate [wins games]
  ifelse games > 0 [
    report ((wins / games)* 100 )
  ] [
    report 0
  ]
end

;; Final edit by GONG
to refresh-my-plots
  plotxy ticks total-cooperation
  plotxy ticks total-betrayal
end
@#$#@#$#@
GRAPHICS-WINDOW
399
10
827
439
-1
-1
20.0
1
10
1
1
1
0
1
1
1
-10
10
-10
10
1
1
1
ticks
30.0

BUTTON
8
19
86
62
NIL
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

PLOT
9
404
394
721
Average Payoff
Iterations
Ave Payoff
0.0
10.0
0.0
5.0
true
true
"" ""
PENS
"random" 1.0 0 -7500403 true "" "if num-random-games > 0 [ plot ((table:get strategy-scores \"random\") / (num-random-games)) ]"
"cooperate" 1.0 0 -2674135 true "" "if num-cooperate-games > 0 [ plot ((table:get strategy-scores \"cooperate\") / (num-cooperate-games)) ]"
"defect" 1.0 0 -13345367 true "" "if num-defect-games > 0 [ plot(( table:get strategy-scores \"defect\") / (num-defect-games)) ]"
"tit-for-tat" 1.0 0 -13840069 true "" "if num-tit-for-tat-games > 0 [ plot (( table:get strategy-scores \"tit-for-tat\") / (num-tit-for-tat-games)) ]"
"unforgiving" 1.0 0 -14835848 true "" "if num-unforgiving-games > 0 [ plot (( table:get strategy-scores \"unforgiving\") / (num-unforgiving-games)) ]"
"win-stay-lose-shift" 1.0 0 -955883 true "" "if num-win-stay-lose-shift-games > 0 [ plot (( table:get strategy-scores \"win-stay-lose-shift\") / (num-win-stay-lose-shift-games)) ]"
"tit-for-tat-forgiveness" 1.0 0 -987046 true "" "if num-tit-for-tat-forgiveness-games > 0 [ plot (( table:get strategy-scores \"tit-for-tat-forgiveness\") / (num-tit-for-tat-forgiveness-games)) ]"

BUTTON
85
19
174
62
NIL
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

SLIDER
8
61
134
94
n-random
n-random
0
20
0.0
1
1
NIL
HORIZONTAL

SLIDER
8
94
134
127
n-cooperate
n-cooperate
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
8
127
134
160
n-defect
n-defect
0
20
0.0
1
1
NIL
HORIZONTAL

SLIDER
133
61
259
94
n-tit-for-tat
n-tit-for-tat
0
20
0.0
1
1
NIL
HORIZONTAL

SLIDER
133
94
259
127
n-unforgiving
n-unforgiving
0
20
0.0
1
1
NIL
HORIZONTAL

TEXTBOX
121
291
242
309
      PAYOFF Matrix:\n\n
11
0.0
0

BUTTON
174
19
260
63
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
6
313
178
346
both-cooperate
both-cooperate
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
182
351
354
384
both-defect
both-defect
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
6
349
178
382
solo-defect
solo-defect
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
181
314
353
347
solo-cooperate
solo-cooperate
0
10
0.0
1
1
NIL
HORIZONTAL

SLIDER
855
75
1023
108
n-games
n-games
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
855
130
1072
163
probability_sequence_ends
probability_sequence_ends
0
1
0.3
0.1
1
NIL
HORIZONTAL

CHOOSER
855
10
1022
55
sequence-end-method
sequence-end-method
"Fixed number" "Probabilistic"
1

SWITCH
855
185
999
218
partner-list
partner-list
0
1
-1000

TEXTBOX
1033
185
1193
259
This switch allows turtles to remember all past partners most recent action, when turned off, the turtle can only remember repeat games\n\nNOTE: it is set at the start of the game and cannot be changed without pressing setup.
7
0.0
1

PLOT
859
316
1127
508
Total betrayal and cooperation
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"cooperate" 1.0 0 -13791810 true "" "plot total-cooperation"
"defect" 1.0 0 -2674135 true "" "plot total-betrayal"

MONITOR
859
263
982
308
NIL
total-cooperation
17
1
11

MONITOR
998
263
1127
308
NIL
total-betrayal
17
1
11

PLOT
6
1181
396
1627
cooperate-score
NIL
NIL
0.0
10.0
0.0
1000.0
true
false
"" "ask turtles with [ strategy = \"cooperate\"][\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color gray\n  plot score\n]"
PENS
"pen-0" 1.0 0 -2674135 true "" "if num-cooperate-games > 0 [ plot ((table:get strategy-scores \"cooperate\") / (table:get strategy-num-agents \"cooperate\")) ]"

PLOT
403
735
852
1186
tit-for-tat score
NIL
NIL
0.0
10.0
0.0
1000.0
true
false
"" "ask turtles with [ strategy = \"tit-for-tat\"][\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color gray\n  plot score\n]"
PENS
"default" 1.0 0 -2674135 true "" "if num-tit-for-tat-games > 0 [ plot ((table:get strategy-scores \"tit-for-tat\") / (table:get strategy-num-agents \"tit-for-tat\")) ]"

PLOT
6
730
397
1178
Random score
NIL
NIL
0.0
10.0
0.0
1000.0
true
false
"" "ask turtles with [ strategy = \"random\"][\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color gray\n  plot score\n]"
PENS
"default" 1.0 0 -2674135 true "" "if num-random-games > 0 [ plot ((table:get strategy-scores \"random\") / (table:get strategy-num-agents \"random\")) ]"

PLOT
396
1186
852
1632
defect score
NIL
NIL
0.0
10.0
0.0
1000.0
true
false
"" "ask turtles with [ strategy = \"defect\"][\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color gray\n  plot score\n]"
PENS
"default" 1.0 0 -2674135 true "" "if num-defect-games > 0 [ plot ((table:get strategy-scores \"defect\") / (table:get strategy-num-agents \"defect\")) ]"

PLOT
853
733
1268
1179
Unforgiving score
NIL
NIL
0.0
10.0
0.0
1000.0
true
false
"" "ask turtles with [ strategy = \"unforgiving\"][\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color gray\n  plot score\n]"
PENS
"default" 1.0 0 -2674135 true "" "if num-unforgiving-games > 0 [ plot ((table:get strategy-scores \"unforgiving\") / (table:get strategy-num-agents \"unforgiving\")) ]"

MONITOR
1060
10
2553
55
NIL
outcomes-dict
17
1
11

SLIDER
134
127
306
160
n-win-stay-lose-shift
n-win-stay-lose-shift
0
20
0.0
1
1
NIL
HORIZONTAL

SLIDER
7
160
184
193
n-tit-for-tat-forgiveness
n-tit-for-tat-forgiveness
0
20
0.0
1
1
NIL
HORIZONTAL

PLOT
853
1187
1273
1629
win-stay-lose-shift score
NIL
NIL
0.0
10.0
0.0
1000.0
true
false
"" "ask turtles with [ strategy = \"win-stay-lose-shift\"][\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color gray\n  plot score\n]"
PENS
"default" 1.0 0 -2674135 true "" "if num-win-stay-lose-shift-games > 0 [ plot ((table:get strategy-scores \"win-stay-lose-shift\") / (table:get strategy-num-agents \"win-stay-lose-shift\")) ]"

PLOT
1270
734
1650
1180
tit-for-tat-forgivness score
NIL
NIL
0.0
10.0
0.0
1000.0
true
false
"" "ask turtles with [ strategy = \"tit-for-tat-forgiveness\"][\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color gray\n  plot score\n]"
PENS
"default" 1.0 0 -2674135 true "" "if num-tit-for-tat-forgiveness-games > 0 [ plot ((table:get strategy-scores \"tit-for-tat-forgiveness\") / (table:get strategy-num-agents \"tit-for-tat-forgiveness\")) ]"

MONITOR
1061
70
1171
115
Random Win Rate
calculate-win-rate random-wins random-games
17
1
11

MONITOR
1187
70
1316
115
Cooperate Win Rate
calculate-win-rate cooperate-wins cooperate-games
17
1
11

MONITOR
1326
69
1436
114
Defect Win Rate
calculate-win-rate defect-wins defect-games
17
1
11

MONITOR
1083
127
1225
172
tit-for-tat Win Rate
calculate-win-rate tit-for-tat-wins tit-for-tat-games
17
1
11

MONITOR
1238
128
1380
173
Unforgiving Win Rate
calculate-win-rate unforgiving-wins unforgiving-games
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model is a multiplayer version of the iterated prisoner's dilemma. It is intended to explore the strategic implications that emerge when the world consists entirely of prisoner's dilemma like interactions. If you are unfamiliar with the basic concepts of the prisoner's dilemma or the iterated prisoner's dilemma, please refer to the PD BASIC and PD TWO PERSON ITERATED models found in the PRISONER'S DILEMMA suite.

## HOW IT WORKS

The PD TWO PERSON ITERATED model demonstrates an interesting concept: When interacting with someone over time in a prisoner's dilemma scenario, it is possible to tune your strategy to do well with theirs. Each possible strategy has unique strengths and weaknesses that appear through the course of the game. For instance, always defect does best of any against the random strategy, but poorly against itself. Tit-for-tat does poorly with the random strategy, but well with itself.

This makes it difficult to determine a single "best" strategy. One such approach to doing this is to create a world with multiple agents playing a variety of strategies in repeated prisoner's dilemma situations. This model does just that. The turtles with different strategies wander around randomly until they find another turtle to play with. (Note that each turtle remembers their last interaction with each other turtle. While some strategies don't make use of this information, other strategies do.)

Payoffs

When two turtles interact, they display their respective payoffs as labels.

Each turtle's payoff for each round will determined as follows:

```text
             | Partner's Action
  Turtle's   |
   Action    |   C       D
 ------------|-----------------
       C     |   3       0
 ------------|-----------------
       D     |   5       1
 ------------|-----------------
  (C = Cooperate, D = Defect)
```

(Note: This way of determining payoff is the opposite of how it was done in the PD BASIC model. In PD BASIC, you were awarded something bad- jail time. In this model, something good is awarded- money.)

## HOW TO USE IT

### Buttons

SETUP: Setup the world to begin playing the multi-person iterated prisoner's dilemma. The number of turtles and their strategies are determined by the slider values.

GO: Have the turtles walk around the world and interact.

GO ONCE: Same as GO except the turtles only take one step.

### Sliders

N-STRATEGY: Multiple sliders exist with the prefix N- then a strategy name (e.g., n-cooperate). Each of these determines how many turtles will be created that use the STRATEGY. Strategy descriptions are found below:

### Strategies

RANDOM - randomly cooperate or defect

COOPERATE - always cooperate

DEFECT - always defect

TIT-FOR-TAT - If an opponent cooperates on this interaction cooperate on the next interaction with them. If an opponent defects on this interaction, defect on the next interaction with them. Initially cooperate.

UNFORGIVING - Cooperate until an opponent defects once, then always defect in each interaction with them.

UNKNOWN - This strategy is included to help you try your own strategies. It currently defaults to Tit-for-Tat.

### Plots

AVERAGE-PAYOFF - The average payoff of each strategy in an interaction vs. the number of iterations. This is a good indicator of how well a strategy is doing relative to the maximum possible average of 5 points per interaction.

## THINGS TO NOTICE

Set all the number of player for each strategy to be equal in distribution.  For which strategy does the average-payoff seem to be highest?  Do you think this strategy is always the best to use or will there be situations where other strategy will yield a higher average-payoff?

Set the number of n-cooperate to be high, n-defects to be equivalent to that of n-cooperate, and all other players to be 0.  Which strategy will yield the higher average-payoff?

Set the number of n-tit-for-tat to be high, n-defects to be equivalent to that of n-tit-for-tat, and all other playerst to be 0.  Which strategy will yield the higher average-payoff?  What do you notice about the average-payoff for tit-for-tat players and defect players as the iterations increase?  Why do you suppose this change occurs?

Set the number n-tit-for-tat to be equal to the number of n-cooperate.  Set all other players to be 0.  Which strategy will yield the higher average-payoff?  Why do you suppose that one strategy will lead to higher or equal payoff?

## THINGS TO TRY

1. Observe the results of running the model with a variety of populations and population sizes. For example, can you get cooperate's average payoff to be higher than defect's? Can you get Tit-for-Tat's average payoff higher than cooperate's? What do these experiments suggest about an optimal strategy?

2. Currently the UNKNOWN strategy defaults to TIT-FOR-TAT. Modify the UNKOWN and UNKNOWN-HISTORY-UPDATE procedures to execute a strategy of your own creation. Test it in a variety of populations.  Analyze its strengths and weaknesses. Keep trying to improve it.

3. Relate your observations from this model to real life events. Where might you find yourself in a similar situation? How might the knowledge obtained from the model influence your actions in such a situation? Why?

## EXTENDING THE MODEL

Relative payoff table - Create a table which displays the average payoff of each strategy when interacting with each of the other strategies.

Complex strategies using lists of lists - The strategies defined here are relatively simple, some would even say naive.  Create a strategy that uses the PARTNER-HISTORY variable to store a list of history information pertaining to past interactions with each turtle.

Evolution - Create a version of this model that rewards successful strategies by allowing them to reproduce and punishes unsuccessful strategies by allowing them to die off.

Noise - Add noise that changes the action perceived from a partner with some probability, causing misperception.

Spatial Relations - Allow turtles to choose not to interact with a partner.  Allow turtles to choose to stay with a partner.

Environmental resources - include an environmental (patch) resource and incorporate it into the interactions.

## NETLOGO FEATURES

Note the use of the `to-report` keyword in the `calc-score` procedure to report a number.

Note the use of lists and turtle ID's to keep a running history of interactions in the `partner-history` turtle variable.

Note how agentsets that will be used repeatedly are stored when created and reused to increase speed.

## RELATED MODELS

PD Basic, PD Two Person Iterated, PD Basic Evolutionary

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (2002).  NetLogo Prisoner's Dilemma N-Person Iterated model.  http://ccl.northwestern.edu/netlogo/models/Prisoner'sDilemmaN-PersonIterated.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2002 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 2002 -->
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
NetLogo 6.4.0
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
