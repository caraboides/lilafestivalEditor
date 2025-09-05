import gleam/bit_array

import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list

pub type Event {
  Event(start: String, end: String, band: String, stage: String)
}

pub type Festival {
  Festival(name: String, id: String, years: List(Int))
}

pub type Data {
  Data(id: String, schedule: dict.Dict(String, Event))
}

pub const festivals = [
  Festival(
    name: "Party.San",
    id: "party_san",
    years: [2019, 2022, 2023, 2024, 2025],
  ),
  Festival(name: "Wtjt", id: "wtjt", years: [2025]),
  Festival(name: "Lila", id: "lila", years: [2022]),
  Festival(name: "Spirit", id: "spirit", years: [2025]),
]

pub fn schedules_from_json(
  json_string: String,
) -> Result(dict.Dict(String, Event), json.DecodeError) {
  //use nicknames <- decode.field("nicknames", decode.list(decode.string))
  let entity_decoder = {
    use start <- decode.field("start", decode.string)
    use end <- decode.field("end", decode.string)
    use band <- decode.field("band", decode.string)
    use stage <- decode.field("stage", decode.string)
    decode.success(Event(start:, end:, band:, stage:))
  }
  json.parse(
    from: json_string,
    using: decode.dict(decode.string, entity_decoder),
  )
}

pub type Band {
  Band(
    img: String,
    logo: String,
    roots: String,
    style: String,
    origin: String,
    spotify: String,
    img_data: Image,
    logo_data: Image,
    cancelled: Bool,
    description: String,
    description_en: String,
  )
}

pub type Image {
  Image(hash: String, width: Int, height: Int)
}

pub fn bands_from_json(
  json_string: String,
) -> Result(dict.Dict(String, Band), json.DecodeError) {
  //use nicknames <- decode.field("nicknames", decode.list(decode.string))
  let img_decoder = {
    use hash <- decode.optional_field("hash", "", decode.string)
    use width <- decode.optional_field("width", 0, decode.int)
    use height <- decode.optional_field("height", 0, decode.int)
    decode.success(Image(hash:, width:, height:))
  }
  let band_decoder = {
    use img <- decode.optional_field("img", "", decode.string)
    use logo <- decode.optional_field("logo", "", decode.string)
    use roots <- decode.optional_field("roots", "", decode.string)
    use style <- decode.optional_field("style", "", decode.string)
    use origin <- decode.optional_field("origin", "", decode.string)
    use img_data <- decode.optional_field(
      "imgData",
      Image(hash: "", width: 0, height: 0),
      img_decoder,
    )
    use spotify <- decode.optional_field("spotify", "", decode.string)
    use logo_data <- decode.optional_field(
      "logoData",
      Image(hash: "", width: 0, height: 0),
      img_decoder,
    )
    use cancelled <- decode.optional_field("cancelled", False, decode.bool)
    use description <- decode.optional_field("description", "", decode.string)
    use description_en <- decode.optional_field(
      "description_en",
      "",
      decode.string,
    )
    decode.success(Band(
      img:,
      logo:,
      roots:,
      style:,
      origin:,
      spotify:,
      img_data:,
      logo_data:,
      cancelled:,
      description:,
      description_en:,
    ))
  }
  json.parse(from: json_string, using: decode.dict(decode.string, band_decoder))
}

pub fn event_to_json(event: Event) -> json.Json {
  json.object([
    #("start", json.string(event.start)),
    #("end", json.string(event.end)),
    #("band", json.string(event.band)),
    #("stage", json.string(event.stage)),
  ])
}

pub fn image_to_json(image: Image) -> json.Json {
  json.object([
    #("hash", json.string(image.hash)),
    #("width", json.int(image.width)),
    #("height", json.int(image.height)),
  ])
}

pub fn band_to_json(band: Band) -> json.Json {
  json.object([
    #("img", json.string(band.img)),
    #("logo", json.string(band.logo)),
    #("roots", json.string(band.roots)),
    #("style", json.string(band.style)),
    #("origin", json.string(band.origin)),
    #("spotify", json.string(band.spotify)),
    #("imgData", image_to_json(band.img_data)),
    #("logoData", image_to_json(band.logo_data)),
    #("cancelled", json.bool(band.cancelled)),
    #("description", json.string(band.description)),
    #("description_en", json.string(band.description_en)),
  ])
}

pub fn bands_to_json(dict: dict.Dict(String, Band)) -> json.Json {
  let pairs =
    dict.fold(dict, list.new(), fn(acc, key, value) {
      let v = band_to_json(value)
      list.append(acc, [#(key, v)])
    })
  json.object(pairs)
}

pub fn dict_to_json(dict: dict.Dict(String, Event)) -> json.Json {
  let pairs =
    dict.fold(dict, list.new(), fn(acc, key, value) {
      let v = event_to_json(value)
      list.append(acc, [#(key, v)])
    })
  json.object(pairs)
}

pub fn encode64_auth(username: String, password: _String) -> String {
  // 2. Das Resultat verarbeiten und das BitArray kodieren
  bit_array.base64_encode(
    bit_array.from_string(username <> ":" <> password),
    True,
  )
}
