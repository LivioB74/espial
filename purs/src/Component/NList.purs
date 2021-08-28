module Component.NList where

import Prelude hiding (div)

import Data.Array (drop, foldMap)
import Data.Maybe (Maybe(..), maybe)
import Data.String (null, split, take) as S
import Data.String.Pattern (Pattern(..))
import Data.Tuple (fst, snd)
import Effect.Aff (Aff)
import Globals (app', mmoment8601)
import Halogen as H
import Halogen.HTML (a, br_, div, text)
import Halogen.HTML as HH
import Halogen.HTML.Properties (href, id_, title)
import Model (Note, NoteSlug)
import Util (class_, fromNullableStr)

data NLAction
  = NLNop

type NLState =
  { notes :: Array Note
  , cur :: Maybe NoteSlug
  , deleteAsk:: Boolean
  , edit :: Boolean
  }


nlist :: forall q i o. Array Note -> H.Component q i o Aff
nlist st' =
  H.mkComponent
    { initialState: const (mkState st')
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }
  where
  app = app' unit

  mkState notes' =
    { notes: notes'
    , cur: Nothing
    , deleteAsk: false
    , edit: false
    }

  render :: NLState -> H.ComponentHTML NLAction () Aff
  render { notes } =
    HH.div_ (map renderNote notes)
    where
      renderNote note =
        div [ id_ (show note.id)
            , class_ ("note w-100 mw7 pa1 mb2"
                     <> if note.shared then "" else " private")] $
           [ div [ class_ "display" ] $
             [ a [ href (linkToFilterSingle note.slug), class_ ("link f5 lh-title")]
               [ text $ if S.null note.title then "[no title]" else note.title ]
             , br_
             , div [ class_ "description mt1 mid-gray" ] (toTextarea (S.take 200 note.text))
             ,  a [ class_ "link f7 dib gray w4"
                  , title (maybe note.created snd (mmoment note))
                  , href (linkToFilterSingle note.slug)]
                [text (maybe " " fst (mmoment note))]
             ]
           ]

  mmoment note = mmoment8601 note.created
  linkToFilterSingle slug = fromNullableStr app.userR <> "/notes/" <> slug
  toTextarea input =
    S.split (Pattern "\n") input
    # foldMap (\x -> [br_, text x])
    # drop 1

  handleAction :: NLAction -> H.HalogenM NLState NLAction () o Aff Unit
  handleAction NLNop = pure unit
