- voting endet: 
    - wenn admin maus beendet
    - alle mäuse haben gevotet // würde ich droppen vielleicht, macht game loop selbstständig, vielleicht brauchen wir das nicht, sonst immer USER -> FE -> WS Message -> Action, damit müsste game selbst Action machen
    - zeit
- edge cases ergebn sich daraus: 
    - was wenn admin maus subway verlässt // voting einfach beenden oder manager switchen

- duration der mouse auf dem Surface: 
    - mouse hat duration on Suface property, welche sich bei eintritt in subway und bei game end erhöht 
    - mouse hat leftAt: Time property, um die zeit zu berechnen wie lange sie drausen war

- cat hat eine caught array mit den IDs der mäuse 
- maybe prohibit that exits can spawn next to each other 


- mergen
- ai feritg machen -> Siu
- ws messages mit Game verbinden -> Matthias, Siu 
- logic fertig machen nach todos.md in logic folder -> Matthisa
- UI anpassen für different games -> Stefan
- room definitions
