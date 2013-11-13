
serverURL = "http://localhost:8080/DiTopWeb/DiTopServlet"

configurations = {}
selectedSet = 0
selectedTopicSize = 0
cloudData = []
svg = {}

slotsHorizontal = 6
slotSize = 150

SORT_BY_GROUP = 1
SORT_BY_DVALUE = 2

fill = d3.scale.category10();
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
$("#ditopButton").click(->
  svg.selectAll(".arc").transition().duration(500).style("opacity",1)
  svg.selectAll(".emptyRect").transition().duration(500).style("opacity",0)
  svg.selectAll(".borderCircle").transition().style("stroke","#666666")
  updateDiTop()
)
$("#resetButton").click(->
  console.log "res"
  zoomInstance.translate([0,0]).scale(1)
  svg.attr("transform", "translate(0,0) scale(1)")
)



@startVis = ->
  zoomInstance = d3.behavior.zoom().scaleExtent([1, 8]).on("zoom", -> zoom())
  svg = d3.select("#vis").append("svg").attr("width",1000).attr("height",1000)
    .call(zoomInstance)
    .append("g")

  createPieBackground()

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
        for k,v of resData
          cloudData.push(v)

        console.log(cloudData)
        drawClouds()

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
      test = b.disValue - a.disValue
      return -1 if test < 0
      return 1 if test > 0
      return 0
    )

  cdGroups = svg.selectAll(".clouds").data(cloudData, (d) -> d.groupName)


  #transform="translate(300,300) rotate(-60)"
  cdGroups.transition().duration(1000)
   .attr("transform",(d,i) -> "translate("+(i%slotsHorizontal*slotSize+ 50)+"," + ((i/slotsHorizontal >>0) *slotSize+50)+")")

  set1Items = getBitIndices(1,cloudData)
  set2Items = getBitIndices(2,cloudData)
  set4Items = getBitIndices(4,cloudData)
  console.log set1Items
  console.log set2Items

  moveGroupItemsDiscrete(set1Items,"set1Items",-13)
  moveGroupItemsDiscrete(set2Items,"set2Items",0)
  moveGroupItemsDiscrete(set4Items,"set4Items",+13)





drawClouds = ->
  cdGroups = svg.selectAll(".clouds").data(cloudData, (d) -> d.groupName)

  #transform="translate(300,300) rotate(-60)"
  d3.transition(cdGroups)
    .attr("transform",(d,i) -> "translate("+(i%slotsHorizontal*slotSize+ 50)+"," + ((i/slotsHorizontal >>0) *slotSize+50)+")")
  cdGroups.exit().remove()
  clouds = cdGroups.enter().append("g").classed("clouds",true)
  clouds
    .attr("transform",(d,i) -> "translate("+(i%slotsHorizontal*slotSize+ 50)+"," + ((i/slotsHorizontal >>0) *slotSize+50)+")")
  clouds.append("circle")
    .attr
        cx: 0
        cy: 0
        r: 45
    .style
        'fill':'#fafafa'
        'stroke': "none"
        'opacity':.9
  clouds.append("circle").classed("borderCircle",true)
    .attr
        cx: 0
        cy: 0
        r: 45
    .style
        'fill':'none'
        'stroke': "#dddddd"
        'stroke-width': (d) -> 1+(d.disValue)*5

  clouds.selectAll("text").data((d) -> d.terms).enter().append("text")
    .attr("x", (d) ->d.xPos)
    .attr("y", (d) ->d.yPos)
    .attr("text-anchor","middle")
    .style
      "font-size": (d) -> (d.size*.9)
      'dominant-baseline': 'middle'

    .text((d) -> d.text)
  for x in [-1..1]
    clouds.append("rect").classed("emptyRect",true)
      .attr
        x: x*13-5
        y: 50
        width: 10
        height: 10


  set1Items = getBitIndices(1,cloudData)
  set2Items = getBitIndices(2,cloudData)
  set4Items = getBitIndices(4,cloudData)
#
  console.log set1Items
  addGroupItems(set1Items,"set1Items",-13, true)
  addGroupItems(set2Items,"set2Items",0,true)
  addGroupItems(set4Items,"set4Items",+13,true)


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
        x: (d) -> cData[d.pos].centerPos.x+500+offsetX-5
        y: (d) -> cData[d.pos].centerPos.y+500+50

  bgRs = setVisItems.selectAll(".bgR").data(setItems, (d) -> d.name)
  bgRs.attr
    x: (d) -> cData[d.pos].centerPos.x+500-49
    y: (d) -> cData[d.pos].centerPos.y+500-49

moveGroupItemsDiscrete = (setItems, className, offsetX) ->
  setVisItems = svg.select("."+className)
  allItems = setVisItems.selectAll(".setItem").data(setItems, (d) -> d.name)
  allItems.transition()
  .attr
    x: (d) -> d.pos%slotsHorizontal*slotSize + 50+offsetX-5
    y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize+100)

  bgRs = setVisItems.selectAll(".bgR").data(setItems, (d) -> d.name)
  bgRs.attr
    x: (d) -> d.pos%slotsHorizontal*slotSize+2
    y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize)+2


addGroupItems = (setItems, className, offsetX, clearAll = false) ->


  setVisItems = svg.select("."+className)
  if setVisItems.empty()
    setVisItems = svg.append("g").classed(className, true)
  else if clearAll
    setVisItems.selectAll(".setItem").remove()
    setVisItems.selectAll(".bgR").remove()


  allItems = setVisItems.selectAll(".setItem").data(setItems, (d) -> d.name)
  allItems.exit().remove()
  allItems.transition()
    .style
      opacity:0
    .transition().duration(2)
      .attr
        x: (d) -> d.pos%slotsHorizontal*slotSize + 50+offsetX-5
        y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize+100)
    .transition().duration(500)
      .style
        opacity:1

  allItems.enter().append("rect").classed("setItem",true)
    .attr
      x: (d) -> d.pos%slotsHorizontal*slotSize + 50+offsetX-5
      y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize+100)
      width: 10
      height: 10
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
      x: (d) -> d.pos%slotsHorizontal*slotSize+2
      y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize)+2

  bgRs.exit().remove()
  bgRs.enter().append("rect").classed("bgR",true)
    .attr
      x: (d) -> d.pos%slotsHorizontal*slotSize+2
      y: (d) -> ((d.pos/slotsHorizontal >>0) *slotSize)+2
      width: 96
      height: 96
    .style
      'fill': 'none'
      'stroke-width': 3
      'opcacity': 0


createPieBackground = ->
  arc = d3.svg.arc()
    .outerRadius(600)
    .innerRadius(0)
    .startAngle((d) ->
      d.start
    )
  .endAngle ((d) ->
      d.end
    )

  g = svg.selectAll(".arc")
  .data([{iname:"set2Items", start:0, end:2*3.14/3.0},{iname:"set1Items", end:4*3.14/3.0, start:2*3.14/3.0},{iname:"set4Items", start:4*Math.PI/3.0, end:2*Math.PI}])
  .enter().append("g")
  .attr("class", "arc");

  g.append("path")
    .attr("d", arc)
    .style("fill",(d) ->
      console.log d
      fill(d.iname))

  g.attr
    "transform": "translate(500,500)"
  .style
    "opacity":0

