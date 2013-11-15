
serverURL = "http://localhost:8080/DiTopWeb/DiTopServlet"

configurations = {}
selectedSet = 0
selectedTopicSize = 0
cloudData = []

svg = {}
allClouds = {}
allAnnotations = {}

width = 1000
height = 1000

offsetVisX = 80
offsetVisY = 80

slotsHorizontal = 6
slotSize = 150

SORT_BY_GROUP = 1
SORT_BY_DVALUE = 2
SORT_BY_CVALUE = 3

fill = d3.scale.category10();
#fill = d3.scale.ordinal().range(["#34CFBE","#FFDB40","#E339A4"])
#fill = d3.scale.ordinal().range(["#0D77CE","#CE0D77","#77CE0D"])
#fill = d3.scale.ordinal().range(["#5cc9ff","#ff5cc9","#c9ff5c"])
zoomInstance = {}

$("#showButton").click( ->
  svg.selectAll(".arc").transition().style("opacity",0)
  key = Object.keys(configurations)[selectedSet]
  topicSize = configurations[key][selectedTopicSize]
  loadDataSet(key+"_"+topicSize)
)
$("#sortButton").click(->
  svg.selectAll(".arc").transition().style("opacity",0)
  sortAndUpdate(SORT_BY_GROUP)
)
$("#sortDButton").click(->
  svg.selectAll(".arc").transition().style("opacity",0)
  sortAndUpdate(SORT_BY_DVALUE)
)
$("#sortCButton").click(->
  svg.selectAll(".arc").transition().style("opacity",0)
  sortAndUpdate(SORT_BY_CVALUE)
)
$("#ditopButton").click(->
  svg.selectAll(".arc").transition().duration(500).style("opacity",1)
  svg.selectAll(".emptyRect").transition().duration(500).style("opacity",0)
#  svg.selectAll(".borderCircle").transition().style("stroke","#666666")
  updateDiTop()
)
$("#resetButton").click(->
  console.log "res"
  zoomInstance.translate([0,0]).scale(1)
  svg.attr("transform", "translate(0,0) scale(1)")
)



@startVis = ->
  zoomInstance = d3.behavior.zoom().scaleExtent([.1, 8]).on("zoom", -> zoom())
  svg = d3.select("#vis").append("svg").attr("width",width).attr("height",height)
    .call(zoomInstance)
    .append("g")

#  create grid lines
  yaxis = d3.range(0,height,50)
  svg.selectAll("line.vertical")
  .data(yaxis)
  .enter().append("svg:line")
  .attr
    "y1": (d)-> d
    "x1": 0
    "y2": (d) -> d
    "x2": width
  .style
    "stroke": "#dddddd"
    "stroke-width": 0.5

  createPieBackground()

  allClouds = svg.append("g").attr("id","allClouds")
  allAnnotations = svg.append("g").attr("id","allAnnotations")

  $.ajax
    url: serverURL,
  #  data: "q="+encodeURIComponent(inputData.toLowerCase())+"&rows=0&facet=true&facet.query=p1:1&facet.query=p2:1&facet.query=p3:1&facet.query=p4:1&facet.query=p5:1&facet.query=p6:1&facet.query=p7:1&facet.query=p8:1&facet.query=p9:1&facet.query=p10:1&facet.query=p11:1&facet.query=p12:1&facet.query=p13:1&facet.query=p14:1&facet.query=p15:1&facet.query=p16:1&facet.field=text&facet.field=sp&facet.field=ngram&facet.sort=count&wt=json",
    dataType: 'jsonp',
    jsonp: 'callback',
    success: (resData) ->
      if resData?
        configurations = resData
        updateDataSet()

      console.log resData



zoom = ->
  svg.attr("transform", "translate(" + d3.event.translate[0] + "," + d3.event.translate[1] + ") scale(" + d3.event.scale + ")")

updateDataSet = ->
  keys = Object.keys(configurations);
  dList = d3.select("#datasetList")
  dList.clear
  elementList= dList.selectAll("a").data(keys)
  elementList.classed("active",(d,i) -> i==selectedSet)
  elementList.enter().append("a")
    .classed("list-group-item",true)
    .classed("active",(d,i) -> i==selectedSet)
    .on("click", (d,i) ->
          selectedSet = i
          selectedTopicSize =0
          updateDataSet()
        )
    .text((d,i) -> d )



  topicSizes = configurations[keys[selectedSet]]
  sList = d3.select("#topicSizesList")
  elementList = sList.selectAll("a").data(topicSizes)
  elementList.enter().append("a")
    .classed("list-group-item",true)
    .classed("active",(d,i) -> i==selectedTopicSize)
    .on("click", (d,i) ->
          selectedTopicSize = i
          updateDataSet()
      )
    .text((d,i) -> d )
  elementList.classed("active",(d,i) -> i==selectedTopicSize)

loadDataSet = (datasetName)->
  console.log(datasetName)
#http://localhost:8080/DiTopWeb/DiTopServlet?dataset=New3000_40
  $.ajax
    url: serverURL,
    data: "dataset="+datasetName,
    dataType: 'jsonp',
    jsonp: 'callback',
    success: (resData) ->
      if resData?
        cloudData = []
        for k,v of resData.termGroups
          cloudData.push(v)

        createLabels(resData.setNamesSorted)
        console.log(cloudData)
        drawClouds()

createLabels = (labelNamesSorted) ->
  groupLabels = d3.select("#groupLabels")
  groupLabels.selectAll(".colorLabel").remove()

  itemCount = 1;
  dataLabelEntries = []
  for k,v of labelNamesSorted
    dataLabelEntries.push
      "itemID" : "set"+itemCount+"Items"
      "itemLabel" : v
    itemCount*=2

  theButtons = groupLabels.selectAll(".colorLabel").data(dataLabelEntries).enter().append("g")
  theButtons.classed("colorLabel",true)
#  .text((d) -> d.itemLabel)
  theButtons.append("rect")
  .attr
    x:(d,i) -> i*150
    y:5
    rx: 5
    ry: 5
    width:10
    height:30
  .style
      "fill": (d) -> fill(d.itemID)
  .on
      'mouseover':  (d)->
        d3.selectAll("."+d.itemID+" .bgR")
        .style
            'stroke':fill(d.itemID)
            'opacity': 0.9
      'mouseout':(d) ->
        d3.selectAll("."+d.itemID+" .bgR")
        .style
            'opacity': 0

  theButtons.append("text")
  .text((d) -> d.itemLabel)
  .attr
      x:(d,i) -> i*150+13
      y:5+20
  .style
    "text-anchor":"left"
    "font":"arial"
    "font-size":"10pt"

updateDiTop = ->
  cdGroups = svg.selectAll(".clouds").data(cloudData, (d) -> d.groupName)
  cdGroups.transition().duration(1000)
    .attr("transform",(d,i) -> "translate("+(d.centerPos.x+500)+"," + (d.centerPos.y+500)+")")

  set1Items = getBitIndices(1,cloudData)
  set2Items = getBitIndices(2,cloudData)
  set4Items = getBitIndices(4,cloudData)

  moveGroupItems(set1Items,"set1Items",-13,cloudData)
  moveGroupItems(set2Items,"set2Items",0, cloudData)
  moveGroupItems(set4Items,"set4Items",+13, cloudData)



sortAndUpdate = (method)->
  if (method==SORT_BY_GROUP)
    cloudData.sort((a,b) ->
      a.inSetBitvector - b.inSetBitvector
    )
  else if (method==SORT_BY_DVALUE)
    cloudData.sort((a,b) ->
      aD = a.disValue
      aD = 0 if isNaN(aD)
      bD = b.disValue
      bD = 0 if isNaN(bD)
      test = bD-aD
      return -1 if test < 0
      return 1 if test > 0
      return 0
    )
  else if (method==SORT_BY_CVALUE)
    cloudData.sort((a,b) ->
      test = b.characteristicValue - a.characteristicValue
      return -1 if test < 0
      return 1 if test > 0
      return 0
    )
  cdGroups = svg.selectAll(".clouds").data(cloudData, (d) -> d.groupName)


  #transform="translate(300,300) rotate(-60)"
  cdGroups.transition().duration(1000)
   .attr("transform",(d,i) -> "translate("+(i%slotsHorizontal*slotSize+ 80)+"," + ((i/slotsHorizontal >>0) *slotSize+80)+")")

  set1Items = getBitIndices(1,cloudData)
  set2Items = getBitIndices(2,cloudData)
  set4Items = getBitIndices(4,cloudData)
  console.log set1Items
  console.log set2Items

  moveGroupItemsDiscrete(set1Items,"set1Items",-13)
  moveGroupItemsDiscrete(set2Items,"set2Items",0)
  moveGroupItemsDiscrete(set4Items,"set4Items",+13)





drawClouds = ->
  cdGroups = allClouds.selectAll(".clouds").data(cloudData, (d) -> d.groupName)

  #transform="translate(300,300) rotate(-60)"
  d3.transition(cdGroups)
    .attr("transform",(d,i) -> "translate("+(i%slotsHorizontal*slotSize+ 80)+"," + ((i/slotsHorizontal >>0) *slotSize+80)+")")
  cdGroups.exit().remove()
  clouds = cdGroups.enter().append("g").classed("clouds",true)
  clouds
    .attr("transform",(d,i) -> "translate("+(i%slotsHorizontal*slotSize+ 80)+"," + ((i/slotsHorizontal >>0) *slotSize+80)+")")
  clouds.append("circle")
    .attr
        cx: 0
        cy: 0
        r: (d) -> d.recommendedRadius *.8
    .style
        'fill':'#fafafa'
        'stroke': "none"
        'opacity': (d) ->
          if d.characteristicValue>0
            return .3 +.7*d.characteristicValue
          else
            return 1

#  clouds.append("circle").classed("borderCircle",true)
#    .attr
#        cx: 0
#        cy: 0
#        r: (d) -> d.recommendedRadius *.8
#    .style
#        'fill':'none'
#
#        'stroke': "#aaaaaa"
#        'stroke-width': 1 #(d) -> 1+(d.disValue)*5


  for sector in [0,2,4]
    clouds.append("path")
    .attr
        "d": (d) ->
          thickness = 1+ d.disValue*5*.5
          thickness = 1 if isNaN(thickness)
          arcLength = 1

          console.log arcLength
          d3.svg.arc()
          .innerRadius(bestRadiusScale(d.recommendedRadius)-thickness)
          .outerRadius(bestRadiusScale(d.recommendedRadius)+thickness)
          .startAngle((sector+1-arcLength) * (Math.PI/3))
          .endAngle((sector+1+arcLength) * (Math.PI/3))()
    .style
        'fill':'aaaaaa'
        'stroke': "#ffffff"
        'stroke-width': 1 #(d) -> 1+(d.disValue)*5

#    clouds.append("path")
#    .attr
#        "d": (d) ->
#          thickness = 1+ d.disValue*5*.5
#          thickness = .9 if isNaN(thickness)
#          arcLength = .25*(0.5 + d.characteristicValue * 1.5)
#          arcLength = 0.1 if (isNaN(arcLength) || arcLength<.4)
#          console.log arcLength
#          d3.svg.arc()
#          .innerRadius(bestRadiusScale(d.recommendedRadius)-thickness-1)
#          .outerRadius(bestRadiusScale(d.recommendedRadius)+thickness+1)
#          .startAngle((sector+1-arcLength) * (Math.PI/3))
#          .endAngle((sector+1+arcLength) * (Math.PI/3))()
#    .style
#        'fill':'#aaaaaa'
        'stroke': "none"
#  clouds.append("path")
#  .attr
#      d: (d)->d.unionShape
#  .style
#      'fill':'#aaaaaa'
#      'opacity':.8




  clouds.selectAll("text").data((d) -> d.terms).enter().append("text")
    .attr("x", (d) ->d.xPos)
    .attr("y", (d) ->d.yPos)
    .attr("text-anchor","middle")
    .style
      "font-size": (d) -> (d.size*.9)
      'dominant-baseline': 'middle'

    .text((d) -> d.text)
#  for x in [-1..1]
#    clouds.append("rect").classed("emptyRect",true)
#      .attr
#        x: x*13-5
#        y: 50
#        width: 10
#        height: 10


  set1Items = getBitIndices(1,cloudData)
  set2Items = getBitIndices(2,cloudData)
  set4Items = getBitIndices(4,cloudData)
#
  console.log set1Items
  addGroupItems(set1Items,"set1Items",2, true)
  addGroupItems(set2Items,"set2Items",0,true)
  addGroupItems(set4Items,"set4Items",4,true)


getBitIndices = (bitmask, cData) ->
  res = []
  for d,i in cData
    res.push({name: d.groupName, pos:i}) if (d.inSetBitvector & bitmask)
  res

moveGroupItems = (setItems, className, offsetX, cData) ->
  setVisItems = svg.select("."+className)
  allItems = setVisItems.selectAll(".setItem").data(setItems, (d) -> d.name)
  allItems.transition()
    .attr
#        x: (d) -> cData[d.pos].centerPos.x+500+offsetX-5
#        y: (d) -> cData[d.pos].centerPos.y+500+cData[d.pos].recommendedRadius*.8+5
        "transform":  (d) -> "translate("+(cData[d.pos].centerPos.x+500)+","+((cData[d.pos].centerPos.y+500))+")"

  bgRs = setVisItems.selectAll(".bgR").data(setItems, (d) -> d.name)
  bgRs.attr
    x: (d) -> cData[d.pos].centerPos.x+500-bestRadius(d.pos)-2
    y: (d) -> cData[d.pos].centerPos.y+500-bestRadius(d.pos)-2

moveGroupItemsDiscrete = (setItems, className, offsetX) ->
  setVisItems = svg.select("."+className)
  allItems = setVisItems.selectAll(".setItem").data(setItems, (d) -> d.name)
  allItems.transition()
  .attr
#    x: (d) -> d.pos%slotsHorizontal*slotSize + offsetVisX+offsetX-5
#    y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize+offsetVisY+cloudData[d.pos].recommendedRadius*.8+5)
    "transform":  (d) -> "translate("+(d.pos%slotsHorizontal*slotSize + offsetVisX)+","+((d.pos/slotsHorizontal >>0) *slotSize+offsetVisY)+")"

  bgRs = setVisItems.selectAll(".bgR").data(setItems, (d) -> d.name)
  bgRs.attr
    x: (d) -> d.pos%slotsHorizontal*slotSize-2+offsetVisX-bestRadius(d.pos)
    y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize)-2+offsetVisY-bestRadius(d.pos)


addGroupItems = (setItems, className, sector, clearAll = false) ->


  setVisItems = allAnnotations.select("."+className)
  if setVisItems.empty()
    setVisItems = allAnnotations.append("g").classed(className, true)
  else if clearAll
    setVisItems.selectAll(".setItem").remove()
    setVisItems.selectAll(".bgR").remove()


  allItems = setVisItems.selectAll(".setItem").data(setItems, (d) -> d.name)
  allItems.exit().remove()
#  allItems.transition()
#    .style
#      opacity:0
#    .transition().duration(2)
#      .attr
#        x: (d) -> d.pos%slotsHorizontal*slotSize + offsetVisX+offsetX-5
#        y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize+offsetVisY+cloudData[d.pos].recommendedRadius*.8+5)
#    .transition().duration(500)
#      .style
#        opacity:1


  allItems.enter().append("g").classed("setItem",true)
    .attr
      "transform":  (d) -> "translate("+(d.pos%slotsHorizontal*slotSize + offsetVisX)+","+((d.pos/slotsHorizontal >>0) *slotSize+offsetVisY)+")"
    .append("path")
    .attr
      "d": (d) ->
        thickness = 1+ cloudData[d.pos].disValue *5*.5
        thickness = 1 if isNaN(thickness)
        arcLength = .25*(0.5 + cloudData[d.pos].characteristicValue * 1.5)
        arcLength = 0.1 if (isNaN(arcLength) || arcLength<.4)
        console.log arcLength
        d3.svg.arc()
        .innerRadius(bestRadius(d.pos)-thickness-2)
        .outerRadius(bestRadius(d.pos)+thickness+2)
        .startAngle((sector+1-arcLength) * (Math.PI/3))
        .endAngle((sector+1 +arcLength) * (Math.PI/3))()
#      x: (d) -> d.pos%slotsHorizontal*slotSize + offsetVisX+offsetX-5
#      y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize+offsetVisY+cloudData[d.pos].recommendedRadius*.8+5)
#      width: 10
#      height: 10



    .style
      'fill': fill(className)
    .on
      'mouseover':  ->
        d3.selectAll("."+className+" .bgR")
        .style
          'stroke':fill(className)
          'opacity': 0.9
#        .transition().duration(500)
#        .style
#          'opacity': .9
      'mouseout':->
        d3.selectAll("."+className+" .bgR")
#        .transition().delay(200).duration(50)
#        .transition().duration(500)
        .style
          'opacity': 0


  bgRs = setVisItems.selectAll(".bgR").data(setItems, (d) -> d.name)
  bgRs.attr
    x: (d) -> d.pos%slotsHorizontal*slotSize-2+offsetVisX-bestRadius(d.pos)
    y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize)-2+offsetVisY-bestRadius(d.pos)

  bgRs.exit().remove()
  bgRs.enter().append("rect").classed("bgR",true)
    .attr
      x: (d) -> d.pos%slotsHorizontal*slotSize-2+offsetVisX-bestRadius(d.pos)
      y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize)-2+offsetVisY-bestRadius(d.pos)
      width: (d) -> bestRadius(d.pos)*2+4
      height: (d) -> bestRadius(d.pos)*2+4
    .style
      'fill': 'none'
      'stroke-width': 3
      'opcacity': 0

bestRadius = (pos) -> bestRadiusScale cloudData[pos].recommendedRadius
bestRadiusScale = (r) -> r*.8


createPieBackground = ->
  arc = d3.svg.arc()
    .outerRadius(1000)
    .innerRadius(0)
    .startAngle((d) ->
      d.start
    )
  .endAngle ((d) ->
      d.end
    )

  g = svg.selectAll(".arc")
  .data([{iname:"set2Items", start:0, end:2*Math.PI/3.0},{iname:"set1Items", end:4*Math.PI/3.0, start:2*Math.PI/3.0},{iname:"set4Items", start:4*Math.PI/3.0, end:2*Math.PI}])
  .enter().append("g")
  .attr("class", "arc");

  g.append("path")
    .attr("d", arc)
    .style("fill",(d) ->
      color = d3.rgb(fill(d.iname)).hsl()
      color.l = .9
      color
    )

  g.attr
    "transform": "translate(500,500)"
  .style
    "opacity":0

